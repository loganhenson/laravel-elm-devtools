port module Main exposing (main)

import Browser
import Html exposing (Html, a, button, div, pre, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Json.Decode exposing (Decoder, Value, errorToString, list, nullable, string)
import Json.Decode.Pipeline exposing (required)
import JsonTree


port receiveLaravelElm : (Value -> msg) -> Sub msg


port connect : () -> Cmd msg


type alias Flags =
    {}


type alias LaravelElm =
    { props : String
    , state : Maybe String
    , url : String
    , page : String
    , ports : List String
    }


type Tab
    = Props
    | State
    | Ports


type alias Model =
    { laravelElm : Maybe LaravelElm
    , error : Maybe String
    , tab : Tab
    , propsTree : Maybe JsonTree.Node
    , propsTreeState : JsonTree.State
    }


type Msg
    = NoOp
    | ReceiveLaravelElm Value
    | Connect
    | SelectTab Tab
    | PropsJsonTreeStateUpdate JsonTree.State


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { laravelElm = Nothing, error = Nothing, tab = Props, propsTree = Nothing, propsTreeState = JsonTree.defaultState }
    , connect ()
    )


decodeLaravelElm : Decoder LaravelElm
decodeLaravelElm =
    Json.Decode.succeed LaravelElm
        |> required "props" string
        |> required "state" (nullable string)
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
                        propsTree = case JsonTree.parseString laravelElm.props of
                            Ok tree -> Just tree
                            Err _ -> Nothing
                    in
                     ( { model
                            | laravelElm = Just laravelElm
                            , propsTree = propsTree
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
                        div [ class "w-full flex flex-1 flex-col" ]
                            [ viewTabMenu model.tab
                            , div [ class "p-2 h-full overflow-y-scroll" ] [ viewTab model ]
                            ]

                    Nothing ->
                        text ""
        ]


viewTabMenu : Tab -> Html Msg
viewTabMenu tab =
    div [ class "w-full flex text-lg border-b" ]
        [ div [ onClick (SelectTab Props), class "p-2 cursor-pointer", classList [ ( "bg-blue-700", tab == Props ) ] ] [ text "Props" ]
        , div [ onClick (SelectTab State), class "p-2 cursor-pointer ml-2", classList [ ( "bg-blue-700", tab == State ) ] ] [ text "State" ]
        , div [ onClick (SelectTab Ports), class "p-2 cursor-pointer ml-2", classList [ ( "bg-blue-700", tab == Ports ) ] ] [ text "Ports" ]
        ]


viewTab : Model -> Html Msg
viewTab model =
    case model.tab of
        Props ->
            div []
                [ case model.propsTree of
                    Just tree ->
                        JsonTree.view tree { onSelect = Nothing, toMsg = PropsJsonTreeStateUpdate, colors = JsonTree.defaultColors } model.propsTreeState

                    Nothing ->
                        text ""
                ]

        State ->
            div []
                [ text <| Maybe.withDefault "" <| Maybe.map (Maybe.withDefault "" << .state) <| model.laravelElm
                ]

        Ports ->
            div [] <| List.map (\name -> div [] [ text name ]) <| Maybe.withDefault [] <| Maybe.map .ports <| model.laravelElm


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.batch [ receiveLaravelElm ReceiveLaravelElm ]
        }
