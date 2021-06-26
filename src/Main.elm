port module Main exposing (main)

import Browser
import Colors
import ElmRecordTree
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (attribute, class, classList)
import Html.Events exposing (onClick)
import Json.Decode exposing (Decoder, Value, errorToString, list, string, value)
import Json.Decode.Pipeline exposing (required)
import JsonTree
import Svg exposing (g, polygon, svg)
import Svg.Attributes exposing (fill, viewBox)


port receiveLaravelElm : (Value -> msg) -> Sub msg


port connect : () -> Cmd msg


type alias Flags =
    {}


type alias LaravelElm =
    { props : Value
    , state : Value
    , url : String
    , page : String
    , ports : List String
    }


type Tab
    = ModelTab
    | PortsTab


type alias Model =
    { laravelElm : Maybe LaravelElm
    , error : Maybe String
    , tab : Tab
    , stateTree : Maybe ElmRecordTree.Node
    , stateTreeState : ElmRecordTree.State
    , propsTree : Maybe JsonTree.Node
    , propsTreeState : JsonTree.State
    }


type Msg
    = NoOp
    | ReceiveLaravelElm Value
    | Connect
    | SelectTab Tab
    | StateJsonTreeStateUpdate ElmRecordTree.State
    | PropsJsonTreeStateUpdate JsonTree.State


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { laravelElm = Nothing, error = Nothing, tab = ModelTab, stateTree = Nothing, stateTreeState = ElmRecordTree.defaultState, propsTree = Nothing, propsTreeState = JsonTree.defaultState }
    , connect ()
    )


decodeLaravelElm : Decoder LaravelElm
decodeLaravelElm =
    Json.Decode.succeed LaravelElm
        |> required "props" value
        |> required "state" value
        |> required "url" string
        |> required "page" string
        |> required "ports" (list string)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveLaravelElm json ->
            case Json.Decode.decodeValue decodeLaravelElm json of
                Ok laravelElm ->
                    let
                        propsTree =
                            case JsonTree.parseValue laravelElm.props of
                                Ok tree ->
                                    Just tree

                                Err _ ->
                                    Nothing

                        stateTree =
                            case ElmRecordTree.parseValue laravelElm.state of
                                Ok tree ->
                                    Just tree

                                Err _ ->
                                    Nothing
                    in
                    ( { model
                        | laravelElm = Just laravelElm
                        , propsTree = propsTree
                        , stateTree = stateTree
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model | error = Just (errorToString error) }, Cmd.none )

        Connect ->
            ( model, connect () )

        SelectTab tab ->
            ( { model | tab = tab }, Cmd.none )

        PropsJsonTreeStateUpdate state ->
            ( { model | propsTreeState = state }, Cmd.none )

        StateJsonTreeStateUpdate state ->
            ( { model | stateTreeState = state }, Cmd.none )

        _ ->
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div [ class "bg-white text-gray-900 flex w-full h-screen overflow-hidden" ]
        [ case model.error of
            Just error ->
                div [] [ text error ]

            Nothing ->
                case model.laravelElm of
                    Just laravelElm ->
                        div [ class "w-full flex flex-1 flex-col text-lg" ]
                            [ viewTopBar model laravelElm
                            , viewTab model
                            ]

                    Nothing ->
                        text ""
        ]


viewTopBar : Model -> LaravelElm -> Html Msg
viewTopBar model laravelElm =
    div [ class "w-full flex justify-between items-center" ]
        [ div [ class "w-10 h-10 mx-2 flex items-center justify-center" ] [ logo ]
        , div [ class "flex p-1 items-center justify-center italic overflow-x-scroll" ] [ text <| "elm/pages/" ++ laravelElm.page ++ ".elm" ]
        , div [ class "flex" ]
            [ viewTabOption model.tab ModelTab "Model"
            , viewTabOption model.tab PortsTab "Ports"
            ]
        ]


viewTabOption : Tab -> Tab -> String -> Html Msg
viewTabOption tab forTab label =
    div [ onClick (SelectTab forTab), class "cursor-pointer text-lg font-bold flex items-end" ]
        [ div
            [ class "pt-2 pb-1 px-4 mx-1 mt-2"
            , class
                (if tab == forTab then
                    "bg-gray-900 text-white rounded-t text-white"

                 else
                    ""
                )
            ]
            [ text label ]
        ]


viewTabTitle : String -> Html msg
viewTabTitle title =
    div [ class "font-bold text-center relative" ]
        [ span [ class "absolute bg-white m-2 px-1 text-gray-900 rounded right-0" ]
            [ text title
            ]
        ]


viewTab : Model -> Html Msg
viewTab model =
    case model.tab of
        ModelTab ->
            div [ class "flex h-full text-lg text-white bg-gray-900" ]
                [ div [ class "flex flex-col flex-1 border-r overflow-x-scroll" ]
                    [ div [ class "p-2 pb-16 overflow-y-scroll" ]
                        [ case model.propsTree of
                            Just tree ->
                                JsonTree.view tree { onSelect = Nothing, toMsg = PropsJsonTreeStateUpdate, colors = Colors.defaultColors } model.propsTreeState

                            Nothing ->
                                text ""
                        ]
                    ]
                , div [ class "flex flex-col flex-1 overflow-x-scroll" ]
                    [ div [ class "p-2 pb-16 overflow-y-scroll" ]
                        [ case model.stateTree of
                            Just tree ->
                                ElmRecordTree.view tree { onSelect = Nothing, toMsg = StateJsonTreeStateUpdate, colors = Colors.defaultColors } model.stateTreeState

                            Nothing ->
                                text ""
                        ]
                    ]
                ]

        PortsTab ->
            div
                [ class "flex flex-col h-full text-lg text-white bg-gray-900 p-2"
                ]
            <|
                List.map (\name -> div [] [ text name ]) <|
                    Maybe.withDefault [] <|
                        Maybe.map .ports <|
                            model.laravelElm


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.batch [ receiveLaravelElm ReceiveLaravelElm ]
        }


logo : Html msg
logo =
    svg [ viewBox "0 0 266 270" ]
        [ g [ fill "none", attribute "fill-rule" "evenodd", attribute "stroke" "none", attribute "stroke-width" "1" ]
            [ g [ attribute "transform" "translate(-193.000000, -96.000000)" ]
                [ g [ attribute "transform" "translate(205.000000, 110.000000)" ]
                    [ polygon [ fill "#FACD66", attribute "points" "47 155.666667 47 83 192 83 192 155.666667 119.5 192" ]
                        []
                    , polygon [ fill "#D99511", attribute "points" "120 83 192 83 192 155.666667 120 192" ]
                        []
                    , polygon [ fill "#EDB024", attribute "points" "47 83.5 119.5 47 192 83.5 119.5 120" ]
                        []
                    , g [ attribute "opacity" "0.445382254" ]
                        [ polygon [ fill "#FACD66", attribute "points" "0 180 0 60 120 120 120 180 120 240" ]
                            []
                        , polygon [ fill "#D99511", attribute "points" "120 120 240 60 240 180 120 240" ]
                            []
                        , polygon [ fill "#EDB024", attribute "points" "0 60 35.3590414 42.3204793 92.7424858 13.6287571 120 0 240 60 120 120 66.5768909 93.2884455" ]
                            []
                        ]
                    ]
                ]
            ]
        ]
