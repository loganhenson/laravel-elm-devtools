module Inspector exposing (State, Value, decodeElm, decodeJson, initialState, view)

{-| A collapsible tree view for two kinds of values:

  - props: plain JSON, shown with JSON syntax (`key: value`)
  - state: the AST produced by js/parser.js from Elm's `Debug.toString`, shown with Elm syntax
    (`key = value`, `Just 1`, `Dict.fromList`, ...)

-}

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, title, type_)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder)
import Set exposing (Set)


type Value
    = Record (List ( String, Value ))
    | Object (List ( String, Value ))
    | Sequence String (List Value)
    | DictValue (List ( Value, Value ))
    | Tuple (List Value)
    | Custom String (List Value)
    | Scalar Kind String


type Kind
    = KString
    | KNumber
    | KBool
    | KMuted


{-| Paths of the nodes the user collapsed. Paths are stable between updates, so collapsed
nodes stay collapsed while the state changes.
-}
type State
    = State (Set String)


initialState : State
initialState =
    State Set.empty



-- DECODERS


decodeJson : Decoder Value
decodeJson =
    Decode.oneOf
        [ Decode.map (Scalar KString << quote) Decode.string
        , Decode.map (Scalar KNumber << String.fromFloat) Decode.float
        , Decode.map (Scalar KBool << boolToJson) Decode.bool
        , Decode.null (Scalar KMuted "null")
        , Decode.map (Sequence "") (Decode.list (Decode.lazy (\_ -> decodeJson)))
        , Decode.map Object (Decode.keyValuePairs (Decode.lazy (\_ -> decodeJson)))
        ]


decodeElm : Decoder Value
decodeElm =
    Decode.field "t" Decode.string
        |> Decode.andThen decodeElmNode


decodeElmNode : String -> Decoder Value
decodeElmNode t =
    let
        lazyElm =
            Decode.lazy (\_ -> decodeElm)

        pair a b =
            Decode.map2 Tuple.pair (Decode.index 0 a) (Decode.index 1 b)

        items =
            Decode.field "items" (Decode.list lazyElm)
    in
    case t of
        "record" ->
            Decode.map Record (Decode.field "fields" (Decode.list (pair Decode.string lazyElm)))

        "list" ->
            Decode.map (Sequence "") items

        "array" ->
            Decode.map (Sequence "Array.fromList ") items

        "set" ->
            Decode.map (Sequence "Set.fromList ") items

        "dict" ->
            Decode.map DictValue (Decode.field "entries" (Decode.list (pair lazyElm lazyElm)))

        "tuple" ->
            Decode.map Tuple items

        "custom" ->
            Decode.map2 Custom (Decode.field "name" Decode.string) (Decode.field "args" (Decode.list lazyElm))

        "string" ->
            Decode.map (Scalar KString << quote) (Decode.field "v" Decode.string)

        "char" ->
            Decode.map (\c -> Scalar KString ("'" ++ c ++ "'")) (Decode.field "v" Decode.string)

        "number" ->
            Decode.map (Scalar KNumber) (Decode.field "v" Decode.string)

        "bool" ->
            Decode.map
                (\b ->
                    Scalar KBool
                        (if b then
                            "True"

                         else
                            "False"
                        )
                )
                (Decode.field "v" Decode.bool)

        "unit" ->
            Decode.succeed (Scalar KMuted "()")

        "function" ->
            Decode.succeed (Scalar KMuted "<function>")

        "internals" ->
            Decode.succeed (Scalar KMuted "<internals>")

        "bytes" ->
            Decode.map (\n -> Scalar KMuted ("<" ++ String.fromInt n ++ " bytes>")) (Decode.field "v" Decode.int)

        "file" ->
            Decode.map (\name -> Scalar KMuted ("<" ++ name ++ ">")) (Decode.field "v" Decode.string)

        _ ->
            Decode.fail ("Unknown value type: " ++ t)


quote : String -> String
quote string =
    "\""
        ++ (string
                |> String.replace "\\" "\\\\"
                |> String.replace "\"" "\\\""
                |> String.replace "\n" "\\n"
                |> String.replace "\t" "\\t"
           )
        ++ "\""


boolToJson : Bool -> String
boolToJson bool =
    if bool then
        "true"

    else
        "false"



-- VIEW


view : (State -> msg) -> State -> Value -> Html msg
view toMsg state value =
    div [ class "font-mono text-xs leading-5" ] [ viewNode toMsg state "$" Nothing value ]


{-| Values that fit on one line: scalars, empty containers and custom types whose
arguments are all scalars (`Just 1`, `Editing 2 "x"`, `Nothing`).
-}
inline : Value -> Maybe (List (Html msg))
inline value =
    case value of
        Scalar kind string ->
            Just [ viewScalar kind string ]

        Custom name args ->
            args
                |> List.map
                    (\arg ->
                        case arg of
                            Scalar kind string ->
                                Just (viewScalar kind string)

                            _ ->
                                Nothing
                    )
                |> combine
                |> Maybe.map (\scalars -> List.intersperse (text " ") (viewCtor name :: scalars))

        Record [] ->
            Just [ muted "{}" ]

        Object [] ->
            Just [ muted "{}" ]

        Sequence prefix [] ->
            Just [ viewPrefix prefix, muted "[]" ]

        DictValue [] ->
            Just [ viewPrefix "Dict.fromList ", muted "[]" ]

        _ ->
            Nothing


viewNode : (State -> msg) -> State -> String -> Maybe (Html msg) -> Value -> Html msg
viewNode toMsg ((State collapsed) as state) path label value =
    case inline value of
        Just parts ->
            div [ class "pl-4 whitespace-pre-wrap break-all" ] (viewLabel label ++ parts)

        Nothing ->
            let
                isCollapsed =
                    Set.member path collapsed

                toggle =
                    if isCollapsed then
                        Set.remove path collapsed

                    else
                        Set.insert path collapsed
            in
            div []
                [ button
                    [ type_ "button"
                    , class "flex w-full text-left whitespace-pre-wrap break-all hover:bg-gray-100 dark:hover:bg-white/5"
                    , onClick (toMsg (State toggle))
                    , title
                        (if isCollapsed then
                            "Expand"

                         else
                            "Collapse"
                        )
                    ]
                    [ span [ class "inline-block w-4 shrink-0 text-center text-gray-400 select-none" ]
                        [ text
                            (if isCollapsed then
                                "▸"

                             else
                                "▾"
                            )
                        ]
                    , span [] (viewLabel label ++ summary value)
                    ]
                , if isCollapsed then
                    text ""

                  else
                    div [ class "ml-2 border-l border-gray-200 pl-2 dark:border-white/10" ]
                        (children toMsg state path value)
                ]


summary : Value -> List (Html msg)
summary value =
    let
        count n singular plural =
            muted
                (" "
                    ++ String.fromInt n
                    ++ " "
                    ++ (if n == 1 then
                            singular

                        else
                            plural
                       )
                )
    in
    case value of
        Record fields ->
            [ muted "{…}", count (List.length fields) "field" "fields" ]

        Object fields ->
            [ muted "{…}", count (List.length fields) "key" "keys" ]

        Sequence prefix items ->
            [ viewPrefix prefix, muted "[…]", count (List.length items) "item" "items" ]

        DictValue entries ->
            [ viewPrefix "Dict.fromList ", muted "[…]", count (List.length entries) "entry" "entries" ]

        Tuple items ->
            [ muted ("(" ++ String.repeat (List.length items - 1) "," ++ ")") ]

        Custom name _ ->
            [ viewCtor name ]

        Scalar kind string ->
            [ viewScalar kind string ]


children : (State -> msg) -> State -> String -> Value -> List (Html msg)
children toMsg state path value =
    let
        child key label =
            viewNode toMsg state (path ++ "." ++ key) (Just label)

        indexed =
            List.indexedMap (\i -> child (String.fromInt i) (muted (String.fromInt i ++ ": ")))
    in
    case value of
        Record fields ->
            List.map (\( name, v ) -> child name (span [] [ fieldName name, muted " = " ]) v) fields

        Object fields ->
            List.map (\( name, v ) -> child name (span [] [ fieldName name, muted ": " ]) v) fields

        Sequence _ items ->
            indexed items

        Tuple items ->
            indexed items

        Custom _ args ->
            List.indexedMap (\i -> viewNode toMsg state (path ++ "." ++ String.fromInt i) Nothing) args

        DictValue entries ->
            List.indexedMap
                (\i ( key, v ) ->
                    child (String.fromInt i) (span [] (inlineKey key ++ [ muted " => " ])) v
                )
                entries

        Scalar _ _ ->
            []


{-| Dict keys are usually scalars; anything else is summarized.
-}
inlineKey : Value -> List (Html msg)
inlineKey key =
    Maybe.withDefault (summary key) (inline key)


viewLabel : Maybe (Html msg) -> List (Html msg)
viewLabel label =
    Maybe.withDefault [] (Maybe.map List.singleton label)


viewScalar : Kind -> String -> Html msg
viewScalar kind string =
    span
        [ class
            (case kind of
                KString ->
                    "text-red-700 dark:text-orange-300"

                KNumber ->
                    "text-blue-700 dark:text-violet-300"

                KBool ->
                    "text-purple-700 dark:text-purple-300"

                KMuted ->
                    "text-gray-500 dark:text-gray-400"
            )
        ]
        [ text string ]


viewCtor : String -> Html msg
viewCtor name =
    span [ class "font-semibold text-teal-700 dark:text-teal-300" ] [ text name ]


viewPrefix : String -> Html msg
viewPrefix prefix =
    if prefix == "" then
        text ""

    else
        span [ class "text-teal-700 dark:text-teal-300" ] [ text prefix ]


fieldName : String -> Html msg
fieldName name =
    span [ class "text-fuchsia-800 dark:text-sky-300" ] [ text name ]


muted : String -> Html msg
muted string =
    span [ class "text-gray-500 dark:text-gray-400" ] [ text string ]


combine : List (Maybe a) -> Maybe (List a)
combine =
    List.foldr (Maybe.map2 (::)) (Just [])
