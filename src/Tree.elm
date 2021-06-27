module Tree exposing (..)

import Dict exposing (Dict)
import Html exposing (Attribute, Html, text)
import Html.Attributes exposing (style)
import Html.Events
import Json.Decode as Decode exposing (Decoder)
import Set exposing (Set)


{-| Configuration of the JSON tree view. It describes how to map events in the tree view
into events that your app understands.
Since the `Config` contains functions, it should never be held in your model. It should
only appear in your `view` code.
`colors` may be defaultColors, or another color set
`onSelect` should be set to `Nothing` for most users. However, if you want to make the
tree's leaf nodes selectable, you should provide a function that takes the selected `KeyPath`
and acts on it.
`toMsg` provides an updated `State` to your application which you should use to overwrite
the previous state.
-}
type alias Config msg =
    { colors : Colors
    , onSelect : Maybe (KeyPath -> msg)
    , toMsg : State -> msg
    }


{-| The state of the JSON tree view. Note that this is just the runtime state needed to
implement things like expand/collapse--it is _not_ the tree data itself.
You should store the current state in your model.
-}
type State
    = State (Set KeyPath)


{-| A node in the tree
-}
type alias Node =
    { value : TaggedValue
    , keyPath : KeyPath
    }


{-| A tagged value
-}
type TaggedValue
    = TString String
    | TFloat Float
    | TBool Bool
    | TList (List Node)
    | TDict (Dict String Node)
    | TNull


{-| The path to a piece of data in the tree.
-}
type alias KeyPath =
    String


type alias Css =
    { root : List ( String, String )
    , ul : List ( String, String )
    , li : List ( String, String )
    , collapser : List ( String, String )
    , fieldName : List ( String, String )
    , string : Colors -> List ( String, String )
    , number : Colors -> List ( String, String )
    , bool : Colors -> List ( String, String )
    , null : Colors -> List ( String, String )
    , selectable : Colors -> List ( String, String )
    }


{-| Parse a JSON value as a tree.
-}
parseValue : Decode.Value -> Result Decode.Error Node
parseValue json =
    let
        rootKeyPath =
            ""

        decoder =
            Decode.map (annotate rootKeyPath) coreDecoder
    in
    Decode.decodeValue decoder json



-- EXPAND/COLLAPSE --


lazyStateChangeOnClick : (() -> State) -> (State -> msg) -> Attribute msg
lazyStateChangeOnClick newStateThunk toMsg =
    {- This is semantically equivalent to `onClick (toMsg newState)`, but defers the computation
       of the new `State` until the event is delivered/decoded.
    -}
    let
        force =
            \thunk -> thunk ()
    in
    newStateThunk
        |> Decode.succeed
        |> Decode.map (force >> toMsg)
        |> Html.Events.on "click"


{-| Initial state where the entire tree is fully expanded.
-}
defaultState : State
defaultState =
    stateFullyExpanded


stateFullyExpanded : State
stateFullyExpanded =
    State (Set.fromList [])


expand : KeyPath -> State -> State
expand keyPath ((State hiddenPaths) as state) =
    State (Set.remove keyPath hiddenPaths)


collapse : KeyPath -> State -> State
collapse keyPath ((State hiddenPaths) as state) =
    State (Set.insert keyPath hiddenPaths)


isCollapsed : KeyPath -> State -> Bool
isCollapsed keyPath ((State hiddenPaths) as state) =
    Set.member keyPath hiddenPaths


coreDecoder : Decoder Node
coreDecoder =
    let
        makeNode v =
            { value = v, keyPath = "" }
    in
    Decode.oneOf
        [ Decode.map (makeNode << TString) Decode.string
        , Decode.map (makeNode << TFloat) Decode.float
        , Decode.map (makeNode << TBool) Decode.bool
        , Decode.map (makeNode << TList) (Decode.list (Decode.lazy (\_ -> coreDecoder)))
        , Decode.map (makeNode << TDict) (Decode.dict (Decode.lazy (\_ -> coreDecoder)))
        , Decode.null (makeNode TNull)
        ]


annotate : String -> Node -> Node
annotate pathSoFar node =
    let
        annotateList index val =
            annotate (pathSoFar ++ "[" ++ String.fromInt index ++ "]") val

        annotateDict fieldName val =
            annotate (pathSoFar ++ "." ++ fieldName) val
    in
    case node.value of
        TString _ ->
            { node | keyPath = pathSoFar }

        TFloat _ ->
            { node | keyPath = pathSoFar }

        TBool _ ->
            { node | keyPath = pathSoFar }

        TNull ->
            { node | keyPath = pathSoFar }

        TList children ->
            { node
                | keyPath = pathSoFar
                , value = TList (List.indexedMap annotateList children)
            }

        TDict dict ->
            { node
                | keyPath = pathSoFar
                , value = TDict (Dict.map annotateDict dict)
            }


{-| Parse a JSON string as a tree.
-}
parseString : String -> Result Decode.Error Node
parseString string =
    Decode.decodeString Decode.value string
        |> Result.andThen parseValue


{-| The colors to be used when showing elements of the JSON Tree.
The strings must be valid CSS colors (e.g. "red", "#ff0000").
-}
type alias Colors =
    { string : String
    , number : String
    , bool : String
    , null : String
    , selectable : String
    }


{-| The defaults colors, which are suitable for a light background.
-}
defaultColors : Colors
defaultColors =
    { string = "#77ff77"
    , number = "#03a9f4"
    , bool = "white"
    , null = "light-gray"
    , selectable = "#fafad2"
    }


css : Css
css =
    { root =
        [ ( "white-space", "pre" )
        ]
    , ul =
        [ ( "list-style-type", "none" )
        , ( "margin-left", "26px" )
        , ( "padding-left", "0px" )
        ]
    , li =
        [ ( "position", "relative" )
        ]
    , collapser =
        [ ( "position", "absolute" )
        , ( "cursor", "pointer" )
        , ( "top", "1px" )
        , ( "left", "-15px" )
        , ( "left", "-15px" )
        , ( "width", "100%" )
        ]
    , fieldName =
        []
    , string = \colors -> [ ( "color", colors.string ) ]
    , number = \colors -> [ ( "color", colors.number ) ]
    , bool = \colors -> [ ( "color", colors.bool ) ]
    , null = \colors -> [ ( "color", colors.null ) ]
    , selectable =
        \colors ->
            [ ( "background-color", colors.selectable )
            , ( "cursor", "pointer" )
            ]
    }


styleList : List ( String, String ) -> List (Html.Attribute msg)
styleList styles =
    List.map (\( name, value ) -> style name value) styles


{-| Inserts a `<style>...</style>` element into the DOM in order to style
CSS pseudo-elements such as hover. This is the technique used by elm-css.
-}
hoverStyles : Config msg -> Html msg
hoverStyles config =
    let
        selectableStyleString =
            css.selectable config.colors
                |> List.map (\( name, value ) -> name ++ ": " ++ value ++ ";")
                |> String.join "\n"

        styleBody =
            "." ++ selectableNodeClass ++ ":hover {\n" ++ selectableStyleString ++ "\n}\n"
    in
    Html.node "style" [] [ text styleBody ]


selectableNodeClass =
    "selectableJsonTreeNode"
