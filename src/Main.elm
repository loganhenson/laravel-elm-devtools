port module Main exposing (main)

import Browser
import Html exposing (Html, a, button, code, div, h2, li, p, span, text, ul)
import Html.Attributes exposing (attribute, class, href, target, title, type_)
import Html.Events exposing (onClick)
import Inspector
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline exposing (optional, required)
import Svg exposing (g, polygon, svg)
import Svg.Attributes exposing (fill, viewBox)


{-| A page sent by panel.js: what Laravel Elm posted from the inspected page, with the
`Debug.toString` state already parsed into an AST (or the parse error).
-}
port receivePage : (Value -> msg) -> Sub msg


{-| The inspected page navigated (full page load).
-}
port pageNavigated : (() -> msg) -> Sub msg


port requestPage : () -> Cmd msg


type alias Page =
    { page : String
    , url : String
    , props : Result String Inspector.Value
    , state : StateValue
    , ports : List String
    }


type StateValue
    = NoState
    | StateValue Inspector.Value
    | StateError String String


type Tab
    = ModelTab
    | PortsTab


type alias Model =
    { page : Maybe Page
    , error : Maybe String
    , tab : Tab
    , propsTree : Inspector.State
    , stateTree : Inspector.State
    }


type Msg
    = ReceivePage Value
    | PageNavigated
    | Refresh
    | SelectTab Tab
    | SetPropsTree Inspector.State
    | SetStateTree Inspector.State


init : () -> ( Model, Cmd Msg )
init _ =
    ( { page = Nothing
      , error = Nothing
      , tab = ModelTab
      , propsTree = Inspector.initialState
      , stateTree = Inspector.initialState
      }
    , requestPage ()
    )


decodePage : Decoder Page
decodePage =
    Decode.succeed Page
        |> required "page" Decode.string
        |> required "url" Decode.string
        |> required "props" (Decode.map (Result.mapError Decode.errorToString << Decode.decodeValue Inspector.decodeJson) Decode.value)
        |> required "state" decodeStateValue
        |> optional "ports" (Decode.list Decode.string) []


decodeStateValue : Decoder StateValue
decodeStateValue =
    Decode.oneOf
        [ Decode.null NoState
        , Decode.map2 StateError (Decode.field "error" Decode.string) (Decode.field "raw" Decode.string)
        , Decode.map StateValue (Decode.field "ast" Inspector.decodeElm)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceivePage json ->
            case Decode.decodeValue decodePage json of
                Ok page ->
                    let
                        samePage =
                            Maybe.map .page model.page == Just page.page
                    in
                    ( { model
                        | page = Just page
                        , error = Nothing
                        , propsTree =
                            if samePage then
                                model.propsTree

                            else
                                Inspector.initialState
                        , stateTree =
                            if samePage then
                                model.stateTree

                            else
                                Inspector.initialState
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error) }, Cmd.none )

        PageNavigated ->
            ( { model | page = Nothing, error = Nothing }, Cmd.none )

        Refresh ->
            ( model, requestPage () )

        SelectTab tab ->
            ( { model | tab = tab }, Cmd.none )

        SetPropsTree tree ->
            ( { model | propsTree = tree }, Cmd.none )

        SetStateTree tree ->
            ( { model | stateTree = tree }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "flex h-screen flex-col overflow-hidden bg-white text-gray-900 dark:bg-[#202124] dark:text-gray-200" ]
        [ case model.page of
            Just page ->
                div [ class "flex min-h-0 flex-1 flex-col" ]
                    [ viewTopBar model page
                    , viewError model.error
                    , viewTab model page
                    ]

            Nothing ->
                div [ class "flex min-h-0 flex-1 flex-col" ]
                    [ viewError model.error
                    , viewWaiting
                    ]
        ]


viewTopBar : Model -> Page -> Html Msg
viewTopBar model page =
    div [ class "flex shrink-0 items-center gap-3 border-b border-gray-200 px-2 text-xs dark:border-white/10" ]
        [ div [ class "size-5 shrink-0" ] [ logo ]
        , div [ class "flex min-w-0 flex-1 items-baseline gap-2 py-2" ]
            [ span [ class "font-semibold", title ("resources/elm/pages/" ++ String.replace "." "/" page.page ++ ".elm") ] [ text page.page ]
            , span [ class "truncate text-gray-500 dark:text-gray-400", title page.url ] [ text page.url ]
            ]
        , div [ class "flex shrink-0 self-stretch" ]
            [ viewTabOption model.tab ModelTab "Model"
            , viewTabOption model.tab PortsTab ("Ports (" ++ String.fromInt (List.length page.ports) ++ ")")
            ]
        , button
            [ type_ "button"
            , class "shrink-0 rounded px-2 py-1 text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/5"
            , title "Ask the page to send its props and state again"
            , onClick Refresh
            ]
            [ text "⟳" ]
        ]


viewTabOption : Tab -> Tab -> String -> Html Msg
viewTabOption current tab label =
    button
        [ type_ "button"
        , onClick (SelectTab tab)
        , class "border-b-2 px-3"
        , class
            (if current == tab then
                "border-blue-600 text-gray-900 dark:border-blue-400 dark:text-white"

             else
                "border-transparent text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
            )
        ]
        [ text label ]


viewError : Maybe String -> Html msg
viewError error =
    case error of
        Just message ->
            div [ class "shrink-0 border-b border-red-200 bg-red-50 px-3 py-2 font-mono text-xs whitespace-pre-wrap text-red-800 dark:border-red-900 dark:bg-red-950 dark:text-red-200" ]
                [ text ("Laravel Elm DevTools could not read the message from the page:\n" ++ message) ]

        Nothing ->
            text ""


viewTab : Model -> Page -> Html Msg
viewTab model page =
    case model.tab of
        ModelTab ->
            div [ class "grid min-h-0 flex-1 grid-cols-1 grid-rows-2 sm:grid-cols-2 sm:grid-rows-1" ]
                [ viewSection "Props" "The props your controller passed to Elm::render (JSON)." <|
                    case page.props of
                        Ok props ->
                            Inspector.view SetPropsTree model.propsTree props

                        Err error ->
                            viewNote error
                , viewSection "State" "The page's state record (from Debug.toString)." <|
                    case page.state of
                        StateValue state ->
                            Inspector.view SetStateTree model.stateTree state

                        StateError error raw ->
                            div []
                                [ viewNote ("Could not parse the state: " ++ error)
                                , div [ class "mt-2 font-mono text-xs whitespace-pre-wrap break-all" ] [ text raw ]
                                ]

                        NoState ->
                            div [ class "space-y-2" ]
                                [ viewNote "No state received yet."
                                , viewNote "State is only sent by development builds: run `npm run dev` (a `npm run build` bundle has the state messages compiled out). It updates after every Msg."
                                ]
                ]

        PortsTab ->
            div [ class "min-h-0 flex-1 overflow-auto p-3 text-xs" ]
                [ p [ class "mb-2 text-gray-500 dark:text-gray-400" ]
                    [ text "Ports of this page that JavaScript is subscribed to (Laravel Elm's own and the ones you registered with LaravelElm.register)." ]
                , if List.isEmpty page.ports then
                    viewNote "None."

                  else
                    ul [ class "space-y-1 font-mono" ] (List.map (\name -> li [] [ text name ]) page.ports)
                ]


viewSection : String -> String -> Html msg -> Html msg
viewSection name description content =
    div [ class "flex min-h-0 min-w-0 flex-col border-gray-200 not-last:border-b sm:not-last:border-r sm:not-last:border-b-0 dark:border-white/10" ]
        [ h2 [ class "shrink-0 border-b border-gray-200 bg-gray-50 px-3 py-1 text-xs font-semibold dark:border-white/10 dark:bg-white/5", title description ]
            [ text name ]
        , div [ class "min-h-0 flex-1 overflow-auto px-1 py-2" ] [ content ]
        ]


viewNote : String -> Html msg
viewNote note =
    p [ class "px-3 text-xs text-gray-500 dark:text-gray-400" ] [ text note ]


viewWaiting : Html Msg
viewWaiting =
    div [ class "flex flex-1 items-center justify-center overflow-auto p-6" ]
        [ div [ class "max-w-md space-y-3 text-sm" ]
            [ div [ class "flex items-center gap-2" ]
                [ div [ class "size-6" ] [ logo ]
                , h2 [ class "font-semibold" ] [ text "Waiting for a Laravel Elm page…" ]
                ]
            , p [] [ text "The panel shows the props, state and ports of the Elm page in this tab. If nothing shows up:" ]
            , ul [ class "list-disc space-y-1 pl-5 text-gray-600 dark:text-gray-400" ]
                [ li [] [ text "The page must be rendered with ", code [] [ text "Elm::render" ], text "." ]
                , li [] [ text "Laravel Elm only talks to the devtools in debug mode: ", code [] [ text "APP_DEBUG=true" ], text " (or ", code [] [ text "ELM_DEBUG=true" ], text ")." ]
                , li [] [ text "Reload the page if it was opened before the extension was installed or updated." ]
                ]
            , button
                [ type_ "button"
                , class "rounded border border-gray-300 px-3 py-1 hover:bg-gray-100 dark:border-white/20 dark:hover:bg-white/5"
                , onClick Refresh
                ]
                [ text "Check again" ]
            , p [ class "text-xs text-gray-500 dark:text-gray-400" ]
                [ a [ href "https://github.com/loganhenson/laravel-elm#devtools", target "_blank", class "underline" ] [ text "Laravel Elm DevTools docs" ] ]
            ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.batch [ receivePage ReceivePage, pageNavigated (\_ -> PageNavigated) ]
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
