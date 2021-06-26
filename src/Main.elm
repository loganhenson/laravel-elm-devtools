port module Main exposing (main)

import Browser
import ElmRecordTree
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Json.Decode exposing (Decoder, Value, errorToString, list, string, value)
import Json.Decode.Pipeline exposing (required)
import JsonTree


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
    div [ class "bg-gray-800 text-white flex w-full h-screen overflow-hidden" ]
        [ case model.error of
            Just error ->
                div [] [ text error ]

            Nothing ->
                case model.laravelElm of
                    Just laravelElm ->
                        div [ class "w-full flex flex-1 flex-col text-lg" ]
                            [ viewTabMenu model.tab
                            , viewTab model
                            ]

                    Nothing ->
                        text ""
        ]


viewTabMenu : Tab -> Html Msg
viewTabMenu tab =
    div [ class "w-full flex text-lg font-bold border-b" ]
        [ div [ onClick (SelectTab ModelTab), class "p-2 cursor-pointer", classList [ ( "bg-blue-700", tab == ModelTab ) ] ] [ text "Model" ]
        , div [ onClick (SelectTab PortsTab), class "p-2 cursor-pointer ml-2", classList [ ( "bg-blue-700", tab == PortsTab ) ] ] [ text "Ports" ]
        ]


viewTab : Model -> Html Msg
viewTab model =
    case model.tab of
        ModelTab ->
            div [ class "flex h-full text-lg" ]
                [ div [ class "flex flex-col flex-1 border-r" ]
                    [ div [ class "p-2 font-bold" ] [ text "Props" ]
                    , div [ class "p-2 pb-16 h-full overflow-y-scroll" ]
                        [ case model.propsTree of
                            Just tree ->
                                JsonTree.view tree { onSelect = Nothing, toMsg = PropsJsonTreeStateUpdate, colors = JsonTree.defaultColors } model.propsTreeState

                            Nothing ->
                                text ""
                        ]
                    ]
                , div [ class "flex flex-col flex-1" ]
                    [ div [ class "p-2 font-bold" ] [ text "State" ]
                    , div [ class "p-2 pb-16 h-full overflow-y-scroll" ]
                        [ case model.stateTree of
                            Just tree ->
                                ElmRecordTree.view tree { onSelect = Nothing, toMsg = StateJsonTreeStateUpdate, colors = ElmRecordTree.defaultColors } model.stateTreeState

                            Nothing ->
                                text ""
                        ]
                    ]
                ]

        PortsTab ->
            div
                [ class "p-2"
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
