module ElmRecordTree exposing (view)

{-| This library provides a JSON tree view. You feed it JSON, and it transforms it into
interactive HTML.
Features:

  - show JSON as a tree of HTML
  - expand/collapse nodes in the tree
  - expand/collapse the entire tree
  - select scalar values in the tree


# Basic Usage

@docs parseString, parseValue, view


# Types

@docs Config, State, defaultState, Node, TaggedValue, KeyPath


# Expand/Collapse

@docs expandAll, collapseToDepth


# Customizing Colors

@docs Colors, defaultColors


# Uncommon/Advanced Stuff

**Note:** These are rarely needed, but they are there if you need it.

@docs stateToJson, stateFromJson

-}

import Dict exposing (Dict)
import Html exposing (Attribute, Html, div, li, span, text, ul)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Tree exposing (Config, KeyPath, Node, State, TaggedValue(..), collapse, css, expand, hoverStyles, isCollapsed, lazyStateChangeOnClick, selectableNodeClass, styleList)


view : Node -> Config msg -> State -> Html msg
view node config state =
    div
        (styleList css.root)
        (hoverStyles config :: viewNodeInternal 0 config node state)


viewNodeInternal : Int -> Config msg -> Node -> State -> List (Html msg)
viewNodeInternal depth config node state =
    let
        boolToString bool =
            -- workaround for https://github.com/avh4/elm-format/issues/209
            if bool then
                "true"

            else
                "false"

        colors =
            config.colors
    in
    case node.value of
        TString str ->
            viewScalar (css.string colors) ("\"" ++ str ++ "\"") node config

        TFloat x ->
            viewScalar (css.number colors) (String.fromFloat x) node config

        TBool bool ->
            viewScalar (css.bool colors) (boolToString bool) node config

        TNull ->
            viewScalar (css.null colors) "null" node config

        TList nodes ->
            viewArray depth nodes node.keyPath config state

        TDict dict ->
            case ( Dict.get "value" dict |> Maybe.map .value, ((Dict.get "type" dict |> Maybe.map .value) == Just (TString "Custom")) && ((Dict.get "name" dict |> Maybe.map .value) == Just (TString "Just")) ) of
                ( justSomething, True ) ->
                    case justSomething of
                        Just (TDict d) ->
                            case Dict.get "value" d |> Maybe.map .value of
                                Just (TFloat value) ->
                                    [ span [ class "font-bold italic" ] [ text "Just " ] ] ++ viewNodeInternal depth config (Node (TFloat value) node.keyPath) state

                                Just (TDict value) ->
                                    [ span [ class "font-bold italic" ] [ text "Just " ] ] ++ viewNodeInternal depth config (Node (TDict value) node.keyPath) state

                                _ ->
                                    viewDict depth dict node.keyPath config state

                        _ ->
                            viewDict depth dict node.keyPath config state

                _ ->
                    case ( Dict.get "type" dict |> Maybe.map .value, Dict.get "name" dict |> Maybe.map .value, Dict.get "value" dict |> Maybe.map .value ) of
                        ( Just (TString "Type"), Just (TString customType), Nothing ) ->
                            [ span [ class "font-bold italic" ] [ text customType ] ]

                        ( Just (TString "String"), Nothing, Just string ) ->
                            viewNodeInternal depth config (Node string node.keyPath) state

                        ( Just (TString "List"), Nothing, Just list ) ->
                            viewNodeInternal depth config (Node list node.keyPath) state

                        ( Just (TString "Record"), Nothing, Just record ) ->
                            viewNodeInternal depth config (Node record node.keyPath) state

                        ( Just (TString "Number"), Nothing, Just number ) ->
                            viewNodeInternal depth config (Node number node.keyPath) state

                        ( Just (TString "Boolean"), Nothing, Just (TBool bool) ) ->
                            [ span [ class "font-bold italic" ]
                                [ text
                                    (if bool then
                                        "True"

                                     else
                                        "False"
                                    )
                                ]
                            ]

                        _ ->
                            viewDict depth dict node.keyPath config state


viewArray : Int -> List Node -> KeyPath -> Config msg -> State -> List (Html msg)
viewArray depth nodes keyPath config state =
    let
        innerContent =
            if List.isEmpty nodes then
                []

            else if isCollapsed keyPath state then
                [ viewExpandButton depth keyPath config state
                , text "…"
                ]

            else
                [ viewCollapseButton depth keyPath config state
                , ul
                    (styleList css.ul)
                    (List.map viewListItem nodes)
                ]

        viewListItem node =
            li
                (styleList css.li)
                (List.append (viewNodeInternal (depth + 1) config node state) [ text "," ])
    in
    [ text "[" ] ++ innerContent ++ [ text "]" ]


viewDict : Int -> Dict String Node -> KeyPath -> Config msg -> State -> List (Html msg)
viewDict depth dict keyPath config state =
    let
        innerContent =
            if Dict.isEmpty dict then
                []

            else if isCollapsed keyPath state then
                [ viewExpandButton depth keyPath config state
                , text "…"
                ]

            else
                [ viewCollapseButton depth keyPath config state
                , ul
                    (styleList css.ul)
                    (List.map viewListItem (Dict.toList dict))
                ]

        viewListItem ( fieldName, node ) =
            li
                (styleList css.li)
                ([ span (styleList css.fieldName) [ text fieldName ]
                 , text ": "
                 ]
                    ++ viewNodeInternal (depth + 1) config node state
                    ++ [ text "," ]
                )
    in
    [ text "{" ] ++ innerContent ++ [ text "}" ]


viewCollapser : Int -> Config msg -> (() -> State) -> String -> Html msg
viewCollapser depth config newStateThunk displayText =
    if depth == 0 then
        text ""

    else
        span
            (lazyStateChangeOnClick newStateThunk config.toMsg
                :: styleList css.collapser
            )
            [ text displayText ]


viewExpandButton : Int -> KeyPath -> Config msg -> State -> Html msg
viewExpandButton depth keyPath config state =
    viewCollapser depth config (\_ -> expand keyPath state) "+"


viewCollapseButton : Int -> KeyPath -> Config msg -> State -> Html msg
viewCollapseButton depth keyPath config state =
    viewCollapser depth config (\_ -> collapse keyPath state) "-"


viewScalar : List ( String, String ) -> String -> Node -> Config msg -> List (Html msg)
viewScalar someCss str node config =
    List.singleton <|
        span
            ([ id node.keyPath ]
                ++ styleList someCss
                ++ (case config.onSelect of
                        Just onSelect ->
                            [ onClick (onSelect node.keyPath)
                            , class selectableNodeClass
                            ]

                        Nothing ->
                            []
                   )
            )
            [ text str ]
