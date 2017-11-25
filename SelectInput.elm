port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, on, onClick)
import String
import Basics exposing (..)
import List exposing (..)
import Json.Encode exposing (encode, Value, string, int, float, bool, list, object)


{-
   Example latex
   \(x^2 + y^2 = z^2\)

   Ports
   https://hackernoon.com/how-elm-ports-work-with-a-picture-just-one-25144ba43cdd
   https://guide.elm-lang.org/interop/javascript.html

   First convert elm to js
   - elm-make SelectInput.elm --output=SelectInput.js

   Second change extension to html

-}


port reloadEquaion : String -> Cmd msg


port updateEquaion : String -> Cmd msg


port sumitEquation : String -> Cmd msg


port updatingLinkedMathEquation : (String -> msg) -> Sub msg


port updatingMathEquationColor : (String -> msg) -> Sub msg


port updatingMathEquation : (String -> msg) -> Sub msg


port updateErrorMessage : (String -> msg) -> Sub msg


main =
    Html.program
        { view = view
        , update = update
        , init = init
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( Model Tex "" "" "" "#000000" False
    , Cmd.none
    )



-- MODEL


type alias Model =
    { mathType : MathType
    , linkedMathEquation : String
    , mathEquation : String
    , errorMessage : String
    , mathEquationColor : String
    , helpPageOpen : Bool
    }


type MathType
    = MathML
    | AsciiMath
    | Tex


encodeModel : Model -> Value
encodeModel model =
    Json.Encode.object
        [ ( "mathType", Json.Encode.string (toOptionString model.mathType) )
        , ( "linkedMathEquation", Json.Encode.string model.linkedMathEquation )
        , ( "mathEquation", Json.Encode.string model.mathEquation )
        , ( "mathEquationColor", Json.Encode.string model.mathEquationColor )
        ]



--("mathType", toOptionString model.mathType)


valuesWithLabels : List ( MathType, String )
valuesWithLabels =
    [ ( MathML, "MathML" )
    , ( AsciiMath, "AsciiMath" )
    , ( Tex, "Tex" )
    ]



-- often this can be replaced with `toString`


toOptionString : MathType -> String
toOptionString currency =
    case currency of
        MathML ->
            "MathML"

        AsciiMath ->
            "AsciiMath"

        Tex ->
            "Tex"


fromOptionString : String -> MathType
fromOptionString string =
    case string of
        "MathML" ->
            MathML

        "AsciiMath" ->
            AsciiMath

        "Tex" ->
            Tex

        _ ->
            Tex


viewOption : MathType -> Html Msg
viewOption mathType =
    option
        [ value <| toString mathType ]
        [ text <| toString mathType ]



{--------------Update----------------------------------------}


type Msg
    = MathTypeChange String
    | ReloadEquaion
    | SumitEquation
    | SetLinkedMathEquation String
    | UpdateEquaion String
    | ToggleHelpPage Bool
    | UpdateErrorMessage String
    | UpdateMathEquation String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MathTypeChange newMathType ->
            let
                newModel =
                    { model | mathType = fromOptionString newMathType }
            in
                ( newModel, updateEquaion (encode 0 (encodeModel newModel)) )

        -- event to reload the id
        ReloadEquaion ->
            ( model, reloadEquaion "reload" )

        -- event to submit equaion
        -- needs equation
        -- id of the image -- mathEquation
        SumitEquation ->
            ( model, sumitEquation (encode 0 (encodeModel model)) )

        -- ("{\"linkedMathEquation\": \"" ++ model.linkedMathEquation ++ "\",\"mathEquation\": \"" ++ model.mathEquation ++ "\"}")
        -- event to send string
        -- update
        UpdateEquaion str ->
            let
                newModel =
                    { model | mathEquation = str }
            in
                ( newModel, updateEquaion (encode 0 (encodeModel newModel)) )

        --mathEquation =  str,
        SetLinkedMathEquation str ->
            ( { model | linkedMathEquation = str }, Cmd.none )

        ToggleHelpPage bool ->
            ( { model | helpPageOpen = bool }, Cmd.none )

        UpdateErrorMessage string ->
            ( { model | errorMessage = string }, Cmd.none )

        UpdateMathEquation colorChanged ->
            ( { model | mathEquationColor = colorChanged }, Cmd.none )



{-

-}
-- VIEW
{--------------HTML----------------------------------------}


view : Model -> Html Msg
view model =
    div [ id "elmContainer" ]
        [ infoHeader
        , div [ id "siteMainContent" ]
            [ select
                [ onInput MathTypeChange, id "selectMathType" ]
                [ viewOption Tex
                , viewOption MathML
                , viewOption AsciiMath
                ]
            , input [ id "selectColor", type_ "color", onInput UpdateMathEquation, value model.mathEquationColor, placeholder "select a color needs to be in #FFFFFF format" ] []
            , textarea [ id "textAreaMathEquation", onInput UpdateEquaion, value model.mathEquation, placeholder "Equation code placeholder" ] []
            , div []
                [ button [ id "submitMathEquation", onClick SumitEquation ]
                    [ span [] [ text ("add to slide") ]
                    , img [ src iconCopy, classList [ ( "iconInButton", True ) ] ] []
                    ]
                , --button [ onClick (SendToJs "testing")] [text "send Info"],
                  div [ id "reloadContainer" ]
                    [ button [ onClick ReloadEquaion ]
                        [ span [] [ text ("reload") ]
                        , img [ src iconFullLink, classList [ ( "iconInButton", True ) ] ] []
                        ]
                    , button [ onClick (SetLinkedMathEquation ""), hidden (String.isEmpty model.linkedMathEquation) ]
                        [ span [] [ text "unconnect" ]
                        , img [ src iconBrokenLink, classList [ ( "iconInButton", True ) ] ] []
                        ]
                    ]
                ]
            , div [ id "SvgContainer" ]
                [ p [ id "AsciiMathEquation", hidden (AsciiMath /= model.mathType) ] [ text "Ascii `` " ]
                , p [ id "TexEquation", hidden (Tex /= model.mathType) ] [ text "Tex ${}$ " ]
                , div [ hidden (MathML /= model.mathType) ]
                    [ p [] [ text "MathML" ]
                    , p [ id "MathMLEquation" ] [ text "" ]
                    ]
                ]
            , div [ id "ErrorMessage", hidden (String.isEmpty model.errorMessage), onClick (UpdateErrorMessage "") ]
                [ p [] [ text ("Error - " ++ model.errorMessage) ]
                ]
            ]
        , helpPage model
        , infoFooter
        ]


myStyle : Attribute msg
myStyle =
    style
        [ ( "backgroundColor", "red" )
        , ( "height", "90px" )
        , ( "width", "100%" )
        ]


helpPageStyles : Bool -> Attribute msg
helpPageStyles bool =
    if (bool == True) then
        style
            [ ( "transform", "translateX(0)" )
            ]
    else
        style
            [ ( "transform", "translateX(100%)" )
            ]


helpPage : Model -> Html Msg
helpPage model =
    div [ id "helpPage", helpPageStyles model.helpPageOpen ]
        [ h2 [] [ text "Help Page", span [ id "exitIcon", onClick (ToggleHelpPage False) ] [ text " X" ] ]
        , h3 [] [ text "Create an Equation" ]
        , p []
            [ text
                ("To create an image out of your equation you must first select the type of format your math equation is in.  Then type your equation inside the "
                    ++ "text box.  Right underneath the text box will be a example of the output.  Once you are done hit the submit button and it will create a image of the "
                    ++ "equation"
                )
            ]
        , h3 [] [ text "Updating Equation" ]
        , p []
            [ text
                ("To update an image select the image you want and hit the reload icon.  This will bind the image to the extension and whenever you hit the"
                    ++ " button it will update the image.  To stop updating a image hit the unconnect button."
                )
            ]
        , img [ id "logo", src "" ] []
        ]


infoHeader : Html Msg
infoHeader =
    header []
        [ h1 [] [ text "<Math>" ]
        , h1 [] [ text "</Equations>" ]
        , img [ id "helpIcon", onClick (ToggleHelpPage True), src iconHelp ] []
        , img [ id "logo", src logoIcon ] []
        ]


infoFooter : Html Msg
infoFooter =
    footer [ class "info" ]
        [ p []
            [ text "Code at "
            , a [ href "https://github.com/brendena/MathEquationsGoogleSlide", target "blank" ] [ text "Github Repo / For Bug Reports" ]
            ]
        , p []
            [ a [ href "mailto:bafeaturerequest@gmail.com?Subject=Bug%20or%20Feature" ] [ text "Message me" ]
            , text " at bafeaturerequest@gmail.com"
            ]
        ]



{--------------HTML----------------------------------------}
{--------------SubScriptions----------------------------------------}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ updatingLinkedMathEquation SetLinkedMathEquation
        , updatingMathEquation UpdateEquaion
        , updateErrorMessage UpdateErrorMessage
        , updatingMathEquationColor UpdateMathEquation
        ]



{-----------end-SubScriptions----------------------------------------}
{-----------------------Images----------------}


iconFullLink : String
iconFullLink =
    "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz48IURPQ1RZUEUgc3ZnIFBVQkxJQyAiLS8vVzNDLy9EVEQgU1ZHIDEuMS8vRU4iICJodHRwOi8vd3d3LnczLm9yZy9HcmFwaGljcy9TVkcvMS4xL0RURC9zdmcxMS5kdGQiPjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iTGF5ZXJfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgeD0iMHB4IiB5PSIwcHgiIHdpZHRoPSI1MTJweCIgaGVpZ2h0PSI1MTJweCIgdmlld0JveD0iMCAwIDUxMiA1MTIiIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDUxMiA1MTIiIHhtbDpzcGFjZT0icHJlc2VydmUiPjxwYXRoIGZpbGw9IiMwMTAxMDEiIGQ9Ik00NTkuNjU0LDIzMy4zNzNsLTkwLjUzMSw5MC41Yy00OS45NjksNTAtMTMxLjAzMSw1MC0xODEsMGMtNy44NzUtNy44NDQtMTQuMDMxLTE2LjY4OC0xOS40MzgtMjUuODEzbDQyLjA2My00Mi4wNjNjMi0yLjAxNiw0LjQ2OS0zLjE3Miw2LjgyOC00LjUzMWMyLjkwNiw5LjkzOCw3Ljk4NCwxOS4zNDQsMTUuNzk3LDI3LjE1NmMyNC45NTMsMjQuOTY5LDY1LjU2MywyNC45MzgsOTAuNSwwbDkwLjUtOTAuNWMyNC45NjktMjQuOTY5LDI0Ljk2OS02NS41NjMsMC05MC41MTZjLTI0LjkzOC0yNC45NTMtNjUuNTMxLTI0Ljk1My05MC41LDBsLTMyLjE4OCwzMi4yMTljLTI2LjEwOS0xMC4xNzItNTQuMjUtMTIuOTA2LTgxLjY0MS04Ljg5MWw2OC41NzgtNjguNTc4YzUwLTQ5Ljk4NCwxMzEuMDMxLTQ5Ljk4NCwxODEuMDMxLDBDNTA5LjYyMywxMDIuMzQyLDUwOS42MjMsMTgzLjM4OSw0NTkuNjU0LDIzMy4zNzN6IE0yMjAuMzI2LDM4Mi4xODZsLTMyLjIwMywzMi4yMTljLTI0Ljk1MywyNC45MzgtNjUuNTYzLDI0LjkzOC05MC41MTYsMGMtMjQuOTUzLTI0Ljk2OS0yNC45NTMtNjUuNTYzLDAtOTAuNTMxbDkwLjUxNi05MC41YzI0Ljk2OS0yNC45NjksNjUuNTQ3LTI0Ljk2OSw5MC41LDBjNy43OTcsNy43OTcsMTIuODc1LDE3LjIwMywxNS44MTMsMjcuMTI1YzIuMzc1LTEuMzc1LDQuODEzLTIuNSw2LjgxMy00LjVsNDIuMDYzLTQyLjA0N2MtNS4zNzUtOS4xNTYtMTEuNTYzLTE3Ljk2OS0xOS40MzgtMjUuODI4Yy00OS45NjktNDkuOTg0LTEzMS4wMzEtNDkuOTg0LTE4MS4wMTYsMGwtOTAuNSw5MC41Yy00OS45ODQsNTAtNDkuOTg0LDEzMS4wMzEsMCwxODEuMDMxYzQ5Ljk4NCw0OS45NjksMTMxLjAzMSw0OS45NjksMTgxLjAxNiwwbDY4LjU5NC02OC41OTRDMjc0LjU2MSwzOTUuMDkyLDI0Ni40MiwzOTIuMzQyLDIyMC4zMjYsMzgyLjE4NnoiLz48L3N2Zz4="


iconBrokenLink : String
iconBrokenLink =
    "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iaXNvLTg4NTktMSI/PjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iQ2FwYV8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB4PSIwcHgiIHk9IjBweCIgdmlld0JveD0iMCAwIDIxLjgzNCAyMS44MzQiIHN0eWxlPSJlbmFibGUtYmFja2dyb3VuZDpuZXcgMCAwIDIxLjgzNCAyMS44MzQ7IiB4bWw6c3BhY2U9InByZXNlcnZlIj48Zz48cGF0aCBzdHlsZT0iZmlsbDojMDkwNjA5OyIgZD0iTTE0LjY3NCwzLjcxNWgwLjM1N3YzLjIwMmgtMC4zNTdWMy43MTV6IE0xNS4wMzEsNy40NTNoMy4yMDF2MC4zNThoLTMuMjAxVjcuNDUzeiBNNy4zLDE1Ljg4N2gwLjM1N3YzLjIwMUg3LjNWMTUuODg3eiBNNC4wOTgsMTQuOTkzSDcuM3YwLjM1OEg0LjA5OFYxNC45OTN6IE04LjY1MSwxMS45MTNsLTUuNzctNS43NjljLTAuODY5LTAuODY5LTAuODY3LTIuMjgxLDAtMy4xNDljMC4wMTQtMC4wMTMsMC4wMzktMC4wNCwwLjAzOS0wLjA0czAuMDUzLTAuMDUsMC4wNzgtMC4wNzZDMy44NjUsMi4wMTIsNS4yNzYsMi4wMTIsNi4xNDQsMi44OGw2LjAwMSw2LjAwMWwtMC4wMDIsMC4wMDJjMCwwLDAuMDQsMC4wMzksMC4xMTgsMC4xMTdsMC4yODEtMC44OTZsMC45MjQtMC4xNzRsMC4wMzctMC44NDRMNy43MiwxLjMwNWMtMS43MzktMS43MzktNC41Ni0xLjc0LTYuMjk4LTAuMDAyYy0wLjAxOCwwLjAxOC0wLjA0MSwwLjA0LTAuMDU4LDAuMDU5QzEuMzQyLDEuMzgxLDEuMzI3LDEuMzk4LDEuMzA2LDEuNDE5Yy0xLjc0LDEuNzM5LTEuNzQsNC41NTksMCw2LjI5OUw3LjEsMTMuNTEyYzAuMDcyLDAuMDcyLDAuMTMsMC4xMzIsMC4xNzksMC4xOGwtMC4wMDEsMC4wMDFsMC4xMzcsMC4xMzhsMC4yNzMtMC44NzNsMC45MjQtMC4xNzVMOC42NTEsMTEuOTEzeiBNMjAuNTI4LDE0LjExNWwtNS43NjItNS43NTlsLTAuMDMyLDAuNzY5TDEzLjcwMSw5LjMybC0wLjI2NywwLjg1Mmw1LjUyLDUuNTJjMC44NjcsMC44NjgsMC44NjUsMi4yNzktMC4wMDEsMy4xNDdjLTAuMDE1LDAuMDEzLTAuMDM5LDAuMDQtMC4wMzksMC4wNHMtMC4wNTMsMC4wNTEtMC4wNzgsMC4wNzdjLTAuODY2LDAuODY2LTIuMjc4LDAuODY2LTMuMTQ2LTAuMDAybC01Ljc3My01Ljc3M2wtMC4wMzUsMC43OTdsLTEuMDMzLDAuMTk1bC0wLjI2LDAuODMxbDUuNTI2LDUuNTI1YzEuNzM5LDEuNzM5LDQuNTYsMS43NDEsNi4yOTgsMC4wMDNjMC4wMTktMC4wMiwwLjA0MS0wLjA0MSwwLjA1OS0wLjA2MWMwLjAyMS0wLjAxOSwwLjAzNi0wLjAzNiwwLjA1OC0wLjA1N0MyMi4yNjgsMTguNjc2LDIyLjI2OCwxNS44NTYsMjAuNTI4LDE0LjExNXoiLz48L2c+PGc+PC9nPjxnPjwvZz48Zz48L2c+PGc+PC9nPjxnPjwvZz48Zz48L2c+PGc+PC9nPjxnPjwvZz48Zz48L2c+PGc+PC9nPjxnPjwvZz48Zz48L2c+PGc+PC9nPjxnPjwvZz48Zz48L2c+PC9zdmc+"


iconHelp : String
iconHelp =
    "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPCEtLSBTdmcgVmVjdG9yIEljb25zIDogaHR0cDovL3d3dy5vbmxpbmV3ZWJmb250cy5jb20vaWNvbiAtLT4KPCFET0NUWVBFIHN2ZyBQVUJMSUMgIi0vL1czQy8vRFREIFNWRyAxLjEvL0VOIiAiaHR0cDovL3d3dy53My5vcmcvR3JhcGhpY3MvU1ZHLzEuMS9EVEQvc3ZnMTEuZHRkIj4KPHN2ZyBvbmNsaWNrPSJ0b2dnbGVIZWxwUGFnZSgpIiBpZD0iaGVscEljb24iIHZlcnNpb249IjEuMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgeD0iMHB4IiB5PSIwcHgiIHZpZXdCb3g9IjAgMCAxMDAwIDEwMDAiIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDEwMDAgMTAwMCIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSI+CjxtZXRhZGF0YT4gU3ZnIFZlY3RvciBJY29ucyA6IGh0dHA6Ly93d3cub25saW5ld2ViZm9udHMuY29tL2ljb24gPC9tZXRhZGF0YT4KPGc+PHBhdGggZD0iTTUwMC4xLDkuOUMyMjkuNCw5LjksMTAsMjI5LjEsMTAsNDk5LjhjMCwyNzAuNywyMTkuNCw0OTAuMyw0OTAuMSw0OTAuM1M5OTAsNzcwLjUsOTkwLDQ5OS44Qzk5MCwyMjkuMSw3NzAuNyw5LjksNTAwLjEsOS45eiBNNTAwLjMsODc5LjJjLTIwOS41LDAtMzc5LjYtMTY5LjktMzc5LjYtMzc5LjVjMC0yMDkuNCwxNzAtMzc5LDM3OS42LTM3OWMyMDkuMiwwLDM3OSwxNjkuNiwzNzksMzc5Qzg3OS4yLDcwOS40LDcwOS41LDg3OS4yLDUwMC4zLDg3OS4yeiIvPjxwYXRoIGQ9Ik00NTcuNyw2NDUuNWg5M3YtNzIuN2MwLTE5LjYsOS4yLTM4LDMzLjgtNTQuMmMyNC4zLTE2LjEsOTIuNy00OC42LDkyLjctMTM0LjFjMC04NS43LTcxLjgtMTQ0LjctMTMyLTE1Ny4yYy02MC41LTEyLjUtMTI1LjktNC4zLTE3Mi4xLDQ2LjVjLTQxLjYsNDUuMy01MC4zLDgxLjUtNTAuMywxNjAuOWg5M3YtMTguNmMwLTQyLjEsNC45LTg2LjksNjUuNC05OS4xYzMzLTYuNyw2NCwzLjgsODIuMywyMS42YzIxLjEsMjAuNiwyMS4xLDY2LjctMTIuMyw4OS45bC01Mi41LDM1LjVjLTMwLjYsMTkuOC00MC45LDQxLjYtNDAuOSw3My43VjY0NS41TDQ1Ny43LDY0NS41eiIvPjxwYXRoIGQ9Ik01MDQuMyw2ODEuOWMyNi4zLDAsNDcuOCwyMS40LDQ3LjgsNDcuOWMwLDI2LjUtMjEuNSw0Ny44LTQ3LjgsNDcuOGMtMjYuNiwwLTQ4LjMtMjEuNC00OC4zLTQ3LjhDNDU2LjEsNzAzLjMsNDc3LjcsNjgxLjksNTA0LjMsNjgxLjl6Ii8+PC9nPgo8L3N2Zz4="


iconCopy : String
iconCopy =
    "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz48IURPQ1RZUEUgc3ZnIFBVQkxJQyAiLS8vVzNDLy9EVEQgU1ZHIDEuMS8vRU4iICJodHRwOi8vd3d3LnczLm9yZy9HcmFwaGljcy9TVkcvMS4xL0RURC9zdmcxMS5kdGQiPjxzdmcgdmVyc2lvbj0iMS4xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB4PSIwcHgiIHk9IjBweCIgdmlld0JveD0iMCAwIDEwMDAgMTAwMCIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAwIDAgMTAwMCAxMDAwIiB4bWw6c3BhY2U9InByZXNlcnZlIj48bWV0YWRhdGE+IFN2ZyBWZWN0b3IgSWNvbnMgOiBodHRwOi8vd3d3Lm9ubGluZXdlYmZvbnRzLmNvbS9pY29uIDwvbWV0YWRhdGE+PGc+PHBhdGggZD0iTTY5MSwxNjAuOFYxMEgyNjkuNUMyMDYuMyw3Mi42LDE0My4xLDEzNS4yLDgwLDE5Ny44djY0MS40aDIyNy45Vjk5MEg5MjBWMTYwLjhINjkxeiBNMjY5LjUsNjQuNHYxMzQuNEgxMzMuMUMxNzguNSwxNTQsMjI0LDEwOS4yLDI2OS41LDY0LjR6IE0zMDcuOSw4MDEuMkgxMTcuNVYyMzYuOGgxOTAuNVY0Ny45aDM0NC41djExMi45aC0xNTRjLTYzLjUsNjIuOS0xMjcsMTI1LjktMTkwLjUsMTg4LjhWODAxLjJ6IE00OTkuNSwyMTUuMnYxMzQuNUgzNjMuMXYtMWM0NS4xLTQ0LjUsOTAuMi04OSwxMzUuMy0xMzMuNUw0OTkuNSwyMTUuMnogTTg4MS41LDk1MmgtNTM1VjM4Ni42SDUzOFYxOTguOGgzNDMuNVY5NTJ6Ii8+PC9nPjwvc3ZnPg=="


logoIcon : String
logoIcon =
    "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+Cjwh%0D%0ALS0gQ3JlYXRlZCB3aXRoIElua3NjYXBlIChodHRwOi8vd3d3Lmlua3NjYXBlLm9yZy8pIC0tPgoK%0D%0APHN2ZwogICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iCiAgIHht%0D%0AbG5zOmNjPSJodHRwOi8vY3JlYXRpdmVjb21tb25zLm9yZy9ucyMiCiAgIHhtbG5zOnJkZj0iaHR0%0D%0AcDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyIKICAgeG1sbnM6c3ZnPSJo%0D%0AdHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIw%0D%0AMDAvc3ZnIgogICB4bWxuczpzb2RpcG9kaT0iaHR0cDovL3NvZGlwb2RpLnNvdXJjZWZvcmdlLm5l%0D%0AdC9EVEQvc29kaXBvZGktMC5kdGQiCiAgIHhtbG5zOmlua3NjYXBlPSJodHRwOi8vd3d3Lmlua3Nj%0D%0AYXBlLm9yZy9uYW1lc3BhY2VzL2lua3NjYXBlIgogICB3aWR0aD0iMTI4IgogICBoZWlnaHQ9IjEy%0D%0AOCIKICAgdmlld0JveD0iMCAwIDEyOCAxMjgiCiAgIGlkPSJzdmcyIgogICB2ZXJzaW9uPSIxLjEi%0D%0ACiAgIGlua3NjYXBlOnZlcnNpb249IjAuOTEgcjEzNzI1IgogICBzb2RpcG9kaTpkb2NuYW1lPSJs%0D%0Ab2dvU3F1YXJlLnN2ZyIKICAgaW5rc2NhcGU6ZXhwb3J0LWZpbGVuYW1lPSIvaG9tZS9icmVuZGVu%0D%0AL0Rvd25sb2Fkcy9pbWFnZS9sb2dvMTI4YnkxMjgiCiAgIGlua3NjYXBlOmV4cG9ydC14ZHBpPSI5%0D%0AMCIKICAgaW5rc2NhcGU6ZXhwb3J0LXlkcGk9IjkwIj4KICA8ZGVmcwogICAgIGlkPSJkZWZzNCIg%0D%0ALz4KICA8c29kaXBvZGk6bmFtZWR2aWV3CiAgICAgaWQ9ImJhc2UiCiAgICAgcGFnZWNvbG9yPSIj%0D%0AZmZmZmZmIgogICAgIGJvcmRlcmNvbG9yPSIjNjY2NjY2IgogICAgIGJvcmRlcm9wYWNpdHk9IjEu%0D%0AMCIKICAgICBpbmtzY2FwZTpwYWdlb3BhY2l0eT0iMC4wIgogICAgIGlua3NjYXBlOnBhZ2VzaGFk%0D%0Ab3c9IjIiCiAgICAgaW5rc2NhcGU6em9vbT0iMS45Nzk4OTkiCiAgICAgaW5rc2NhcGU6Y3g9Ijk2%0D%0ALjcyMzM5MiIKICAgICBpbmtzY2FwZTpjeT0iMjMuMzIwNTU1IgogICAgIGlua3NjYXBlOmRvY3Vt%0D%0AZW50LXVuaXRzPSJweCIKICAgICBpbmtzY2FwZTpjdXJyZW50LWxheWVyPSJsYXllcjIiCiAgICAg%0D%0Ac2hvd2dyaWQ9ImZhbHNlIgogICAgIHVuaXRzPSJweCIKICAgICBpbmtzY2FwZTp3aW5kb3ctd2lk%0D%0AdGg9IjE4NTUiCiAgICAgaW5rc2NhcGU6d2luZG93LWhlaWdodD0iMTA1NiIKICAgICBpbmtzY2Fw%0D%0AZTp3aW5kb3cteD0iMTM0NSIKICAgICBpbmtzY2FwZTp3aW5kb3cteT0iMjQiCiAgICAgaW5rc2Nh%0D%0AcGU6d2luZG93LW1heGltaXplZD0iMSIgLz4KICA8bWV0YWRhdGEKICAgICBpZD0ibWV0YWRhdGE3%0D%0AIj4KICAgIDxyZGY6UkRGPgogICAgICA8Y2M6V29yawogICAgICAgICByZGY6YWJvdXQ9IiI+CiAg%0D%0AICAgICAgPGRjOmZvcm1hdD5pbWFnZS9zdmcreG1sPC9kYzpmb3JtYXQ+CiAgICAgICAgPGRjOnR5%0D%0AcGUKICAgICAgICAgICByZGY6cmVzb3VyY2U9Imh0dHA6Ly9wdXJsLm9yZy9kYy9kY21pdHlwZS9T%0D%0AdGlsbEltYWdlIiAvPgogICAgICAgIDxkYzp0aXRsZT48L2RjOnRpdGxlPgogICAgICA8L2NjOldv%0D%0Acms+CiAgICA8L3JkZjpSREY+CiAgPC9tZXRhZGF0YT4KICA8ZwogICAgIGlua3NjYXBlOmdyb3Vw%0D%0AbW9kZT0ibGF5ZXIiCiAgICAgaWQ9ImxheWVyMiIKICAgICBpbmtzY2FwZTpsYWJlbD0iQmFja2dy%0D%0Ab3VuZCIKICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmUiPgogICAgPHJlY3QKICAgICAgIHN0eWxl%0D%0APSJjb2xvcjojMDAwMDAwO2NsaXAtcnVsZTpub256ZXJvO2Rpc3BsYXk6aW5saW5lO292ZXJmbG93%0D%0AOnZpc2libGU7dmlzaWJpbGl0eTp2aXNpYmxlO29wYWNpdHk6MTtpc29sYXRpb246YXV0bzttaXgt%0D%0AYmxlbmQtbW9kZTpub3JtYWw7Y29sb3ItaW50ZXJwb2xhdGlvbjpzUkdCO2NvbG9yLWludGVycG9s%0D%0AYXRpb24tZmlsdGVyczpsaW5lYXJSR0I7c29saWQtY29sb3I6IzAwMDAwMDtzb2xpZC1vcGFjaXR5%0D%0AOjE7ZmlsbDojYmZjM2M0O2ZpbGwtb3BhY2l0eToxO2ZpbGwtcnVsZTpub256ZXJvO3N0cm9rZTpu%0D%0Ab25lO3N0cm9rZS13aWR0aDoyLjcyNDk5OTk7c3Ryb2tlLWxpbmVjYXA6cm91bmQ7c3Ryb2tlLWxp%0D%0AbmVqb2luOnJvdW5kO3N0cm9rZS1taXRlcmxpbWl0OjQ7c3Ryb2tlLWRhc2hhcnJheTpub25lO3N0%0D%0Acm9rZS1kYXNob2Zmc2V0OjA7c3Ryb2tlLW9wYWNpdHk6MTtjb2xvci1yZW5kZXJpbmc6YXV0bztp%0D%0AbWFnZS1yZW5kZXJpbmc6YXV0bztzaGFwZS1yZW5kZXJpbmc6YXV0bzt0ZXh0LXJlbmRlcmluZzph%0D%0AdXRvO2VuYWJsZS1iYWNrZ3JvdW5kOmFjY3VtdWxhdGUiCiAgICAgICBpZD0icmVjdDQxNDAiCiAg%0D%0AICAgICB3aWR0aD0iMTI4Ljc1OTg3IgogICAgICAgaGVpZ2h0PSIxMjguNzU5ODkiCiAgICAgICB4%0D%0APSItMC4wOTQyMjYxMjkiCiAgICAgICB5PSItMC4zMDg1MTkzOSIKICAgICAgIHJ5PSIwIgogICAg%0D%0AICAgaW5rc2NhcGU6ZXhwb3J0LXhkcGk9IjkwIgogICAgICAgaW5rc2NhcGU6ZXhwb3J0LXlkcGk9%0D%0AIjkwIiAvPgogIDwvZz4KICA8ZwogICAgIGlua3NjYXBlOmxhYmVsPSJUZXh0IgogICAgIGlua3Nj%0D%0AYXBlOmdyb3VwbW9kZT0ibGF5ZXIiCiAgICAgaWQ9ImxheWVyMSIKICAgICB0cmFuc2Zvcm09InRy%0D%0AYW5zbGF0ZSgwLC05MjQuMzYyMTYpIgogICAgIHN0eWxlPSJkaXNwbGF5OmlubGluZSI+CiAgICA8%0D%0AZwogICAgICAgdHJhbnNmb3JtPSJzY2FsZSgwLjgyOTIyMzg0LDEuMjA1OTQ3KSIKICAgICAgIHN0%0D%0AeWxlPSJmb250LXN0eWxlOm5vcm1hbDtmb250LXdlaWdodDpub3JtYWw7Zm9udC1zaXplOjg1LjQ3%0D%0ANzExOTQ1cHg7bGluZS1oZWlnaHQ6MTI1JTtmb250LWZhbWlseTpzYW5zLXNlcmlmO2xldHRlci1z%0D%0AcGFjaW5nOjBweDt3b3JkLXNwYWNpbmc6MHB4O2ZpbGw6I2ZmZmZmZjtmaWxsLW9wYWNpdHk6MTtz%0D%0AdHJva2U6bm9uZTtzdHJva2Utd2lkdGg6MXB4O3N0cm9rZS1saW5lY2FwOmJ1dHQ7c3Ryb2tlLWxp%0D%0AbmVqb2luOm1pdGVyO3N0cm9rZS1vcGFjaXR5OjEiCiAgICAgICBpZD0idGV4dDQxMzYiPgogICAg%0D%0AICA8cGF0aAogICAgICAgICBkPSJtIDQwLjEyMDM0Miw4NTMuMTUwNzcgMCw2LjAxMDExIC0yLjU4%0D%0ANzY4NiwwIHEgLTEwLjM5MjQ4MiwwIC0xMy45NDAxMTYsLTMuMDg4NTMgLTMuNTA1ODk4LC0zLjA4%0D%0AODUzIC0zLjUwNTg5OCwtMTIuMzEyMzggbCAwLC05Ljk3NTExIHEgMCwtNi4zMDIyNyAtMi4yNTM3%0D%0AOTEsLTguNzIzMDEgLTIuMjUzNzkxLC0yLjQyMDc0IC04LjE4MDQyNzIsLTIuNDIwNzQgbCAtMi41%0D%0ANDU5NDk0LDAgMCwtNS45NjgzNyAyLjU0NTk0OTQsMCBxIDUuOTY4MzczMiwwIDguMTgwNDI3Miwt%0D%0AMi4zNzkgMi4yNTM3OTEsLTIuNDIwNzQgMi4yNTM3OTEsLTguNjM5NTMgbCAwLC0xMC4wMTY4NSBx%0D%0AIDAsLTkuMjIzODUgMy41MDU4OTgsLTEyLjI3MDY0IDMuNTQ3NjM0LC0zLjA4ODUzIDEzLjk0MDEx%0D%0ANiwtMy4wODg1MyBsIDIuNTg3Njg2LDAgMCw1Ljk2ODM3IC0yLjgzODEwNywwIHEgLTUuODg0OSww%0D%0AIC03LjY3OTU4NSwxLjgzNjQyIC0xLjc5NDY4NiwxLjgzNjQzIC0xLjc5NDY4Niw3LjcyMTMyIGwg%0D%0AMCwxMC4zNTA3NSBxIDAsNi41NTI2OSAtMS45MTk4OTYsOS41MTYwMSAtMS44NzgxNTksMi45NjMz%0D%0AMSAtNi40NjkyMTYsNC4wMDY3NCA0LjYzMjc5NCwxLjEyNjg5IDYuNTEwOTUzLDQuMDkwMjEgMS44%0D%0ANzgxNTksMi45NjMzMiAxLjg3ODE1OSw5LjQ3NDI3IGwgMCwxMC4zNTA3NSBxIDAsNS44ODQ5IDEu%0D%0ANzk0Njg2LDcuNzIxMzIgMS43OTQ2ODUsMS44MzY0MiA3LjY3OTU4NSwxLjgzNjQyIGwgMi44Mzgx%0D%0AMDcsMCB6IgogICAgICAgICBpZD0icGF0aDQyMTUiCiAgICAgICAgIGlua3NjYXBlOmNvbm5lY3Rv%0D%0Aci1jdXJ2YXR1cmU9IjAiIC8+CiAgICAgIDxwYXRoCiAgICAgICAgIGQ9Im0gMTE1Ljk1NjI0LDg1%0D%0AMy4xNTA3NyAyLjkyMTU5LDAgcSA1Ljg0MzE2LDAgNy41OTYxMSwtMS43OTQ2OSAxLjc5NDY4LC0x%0D%0ALjc5NDY4IDEuNzk0NjgsLTcuNzYzMDUgbCAwLC0xMC4zNTA3NSBxIDAsLTYuNTEwOTUgMS44Nzgx%0D%0ANiwtOS40NzQyNyAxLjg3ODE2LC0yLjk2MzMyIDYuNTEwOTUsLTQuMDkwMjEgLTQuNjMyNzksLTEu%0D%0AMDQzNDMgLTYuNTEwOTUsLTQuMDA2NzQgLTEuODc4MTYsLTIuOTYzMzIgLTEuODc4MTYsLTkuNTE2%0D%0AMDEgbCAwLC0xMC4zNTA3NSBxIDAsLTUuOTI2NjMgLTEuNzk0NjgsLTcuNzIxMzIgLTEuNzUyOTUs%0D%0ALTEuODM2NDIgLTcuNTk2MTEsLTEuODM2NDIgbCAtMi45MjE1OSwwIDAsLTUuOTY4MzcgMi42Mjk0%0D%0AMywwIHEgMTAuMzkyNDgsMCAxMy44NTY2NCwzLjA4ODUzIDMuNTA1OSwzLjA0Njc5IDMuNTA1OSwx%0D%0AMi4yNzA2NCBsIDAsMTAuMDE2ODUgcSAwLDYuMjE4NzkgMi4yNTM3OSw4LjYzOTUzIDIuMjUzNzks%0D%0AMi4zNzkgOC4xODA0MywyLjM3OSBsIDIuNTg3NjgsMCAwLDUuOTY4MzcgLTIuNTg3NjgsMCBxIC01%0D%0ALjkyNjY0LDAgLTguMTgwNDMsMi40MjA3NCAtMi4yNTM3OSwyLjQyMDc0IC0yLjI1Mzc5LDguNzIz%0D%0AMDEgbCAwLDkuOTc1MTEgcSAwLDkuMjIzODUgLTMuNTA1OSwxMi4zMTIzOCAtMy40NjQxNiwzLjA4%0D%0AODUzIC0xMy44NTY2NCwzLjA4ODUzIGwgLTIuNjI5NDMsMCAwLC02LjAxMDExIHoiCiAgICAgICAg%0D%0AIGlkPSJwYXRoNDIxNyIKICAgICAgICAgaW5rc2NhcGU6Y29ubmVjdG9yLWN1cnZhdHVyZT0iMCIg%0D%0ALz4KICAgIDwvZz4KICA8L2c+CiAgPGcKICAgICBzdHlsZT0iZGlzcGxheTpub25lIgogICAgIHRy%0D%0AYW5zZm9ybT0idHJhbnNsYXRlKDAsLTkyNC4zNjIxNikiCiAgICAgaWQ9Imc0MjA4IgogICAgIGlu%0D%0Aa3NjYXBlOmdyb3VwbW9kZT0ibGF5ZXIiCiAgICAgaW5rc2NhcGU6bGFiZWw9IlRleHQgY29weSIK%0D%0AICAgICBzb2RpcG9kaTppbnNlbnNpdGl2ZT0idHJ1ZSI+CiAgICA8dGV4dAogICAgICAgdHJhbnNm%0D%0Ab3JtPSJzY2FsZSgwLjgyOTIyMzg0LDEuMjA1OTQ3KSIKICAgICAgIHNvZGlwb2RpOmxpbmVzcGFj%0D%0AaW5nPSIxMjUlIgogICAgICAgaWQ9InRleHQ0MjEwIgogICAgICAgeT0iODQ1LjIyMDc2IgogICAg%0D%0AICAgeD0iLTMuNTc4MTY1NSIKICAgICAgIHN0eWxlPSJmb250LXN0eWxlOm5vcm1hbDtmb250LXdl%0D%0AaWdodDpub3JtYWw7Zm9udC1zaXplOjg1LjQ3NzExOTQ1cHg7bGluZS1oZWlnaHQ6MTI1JTtmb250%0D%0ALWZhbWlseTpzYW5zLXNlcmlmO2xldHRlci1zcGFjaW5nOjBweDt3b3JkLXNwYWNpbmc6MHB4O2Zp%0D%0AbGw6I2ZmZmZmZjtmaWxsLW9wYWNpdHk6MTtzdHJva2U6bm9uZTtzdHJva2Utd2lkdGg6MXB4O3N0%0D%0Acm9rZS1saW5lY2FwOmJ1dHQ7c3Ryb2tlLWxpbmVqb2luOm1pdGVyO3N0cm9rZS1vcGFjaXR5OjEi%0D%0ACiAgICAgICB4bWw6c3BhY2U9InByZXNlcnZlIj48dHNwYW4KICAgICAgICAgeT0iODQ1LjIyMDc2%0D%0AIgogICAgICAgICB4PSItMy41NzgxNjU1IgogICAgICAgICBpZD0idHNwYW40MjEyIgogICAgICAg%0D%0AICBzb2RpcG9kaTpyb2xlPSJsaW5lIj57ICB9PC90c3Bhbj48L3RleHQ+CiAgPC9nPgogIDxnCiAg%0D%0AICAgaW5rc2NhcGU6Z3JvdXBtb2RlPSJsYXllciIKICAgICBpZD0ibGF5ZXIzIgogICAgIGlua3Nj%0D%0AYXBlOmxhYmVsPSJMaW5lcyIKICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmUiCiAgICAgc29kaXBv%0D%0AZGk6aW5zZW5zaXRpdmU9InRydWUiPgogICAgPHBhdGgKICAgICAgIHN0eWxlPSJjb2xvcjojMDAw%0D%0AMDAwO2NsaXAtcnVsZTpub256ZXJvO2Rpc3BsYXk6aW5saW5lO292ZXJmbG93OnZpc2libGU7dmlz%0D%0AaWJpbGl0eTp2aXNpYmxlO29wYWNpdHk6MTtpc29sYXRpb246YXV0bzttaXgtYmxlbmQtbW9kZTpu%0D%0Ab3JtYWw7Y29sb3ItaW50ZXJwb2xhdGlvbjpzUkdCO2NvbG9yLWludGVycG9sYXRpb24tZmlsdGVy%0D%0AczpsaW5lYXJSR0I7c29saWQtY29sb3I6IzAwMDAwMDtzb2xpZC1vcGFjaXR5OjE7ZmlsbDojZmZm%0D%0AZmQzO2ZpbGwtb3BhY2l0eToxO2ZpbGwtcnVsZTpub256ZXJvO3N0cm9rZTojMzAzYzQyO3N0cm9r%0D%0AZS13aWR0aDowO3N0cm9rZS1saW5lY2FwOnJvdW5kO3N0cm9rZS1saW5lam9pbjpyb3VuZDtzdHJv%0D%0Aa2UtbWl0ZXJsaW1pdDo0O3N0cm9rZS1kYXNoYXJyYXk6bm9uZTtzdHJva2UtZGFzaG9mZnNldDow%0D%0AO3N0cm9rZS1vcGFjaXR5OjE7Y29sb3ItcmVuZGVyaW5nOmF1dG87aW1hZ2UtcmVuZGVyaW5nOmF1%0D%0AdG87c2hhcGUtcmVuZGVyaW5nOmF1dG87dGV4dC1yZW5kZXJpbmc6YXV0bztlbmFibGUtYmFja2dy%0D%0Ab3VuZDphY2N1bXVsYXRlIgogICAgICAgaWQ9InBhdGg0MjM0IgogICAgICAgZD0ibSAyOC45NjUy%0D%0ANywzNi4wMDg2ODYgYyAwLjMxMDQ3NywtMC40NTE3MTggMC42ODcxNjQsLTAuODU5MjczIDEuMDY0%0D%0AMDc5LC0xLjI2MTAwMiAwLjI1NTg5NCwtMC4zMjYyMDEgMC42MTAzOTgsLTAuNTUxMDc0IDAuOTE4%0D%0AMTgsLTAuODI1MDM5IDAuNzg5ODgsLTAuNzAzMDk0IC0wLjQyMDEwOCwwLjMxNTc2MyAwLjQ4MDY2%0D%0ANCwtMC40MzMyODcgMC41ODY5MDIsLTAuNDc4MzcgMS4xODM4MzQsLTAuOTQ5ODA0IDEuODE5OTcx%0D%0ALC0xLjM2ODA4NiAwLjY2MDQ0MiwtMC40NzIwNTcgMS40MDI3OTksLTAuNzk0NDY1IDIuMTMyNjY3%0D%0ALC0xLjE0OTQ5OSAwLjcyMTA4OSwtMC4zMTc5NjYgMS40ODg1MjIsLTAuNTExNzM1IDIuMjQ5Mjg0%0D%0ALC0wLjcxOTI0MSAwLjc0MzUzNSwtMC4xODg1MTMgMS40OTI4NzEsLTAuMzQyNjAzIDIuMjUyNTQ4%0D%0ALC0wLjQ1NjY5NiAwLjYyNzU1OSwtMC4wODIxNCAxLjI1OTYzMywtMC4xMDMwNTYgMS44OTE4MDIs%0D%0ALTAuMTIxNDIzIDAuNTY0MDUxLC0wLjAxMTc4IDEuMTIzMjQ1LC0wLjAxMTQ2IDEuNjgzMjk4LDAu%0D%0AMDU3NTIgMC42NTg3NCwwLjA2ODQ2IDEuMzEyODMzLDAuMTcwNTM5IDEuOTY0NjY0LDAuMjg0MjQ3%0D%0AIDAuNzc5NjA3LDAuMTIwNDM0IDEuNTU0NzgzLDAuMjYxMTM4IDIuMzI4MzkxLDAuNDEyNTUgMC44%0D%0AODE3NzcsMC4xMzcyNzEgMS43NTE2NTQsMC4zMjA1MDkgMi42MjA3OTYsMC41MTUzNzggMC45Mjcw%0D%0AODMsMC4yMDkwNDUgMS44NDc0MywwLjQ0MjI0OSAyLjc2ODczLDAuNjczMDg2IDAuOTEyMjU4LDAu%0D%0AMjEyNDA0IDEuODIxNTM1LDAuNDQwMjI4IDIuNzIxODUyLDAuNjk1MzAyIDAuODU0Nzk3LDAuMjc4%0D%0AMjMxIDEuNzIwNDA0LDAuNTI0NDkxIDIuNTc4NjYxLDAuNzkyMzU3IDAuNzk2NjQxLDAuMjgxMjc2%0D%0AIDEuNTg2MjkxLDAuNTc5NDUxIDIuMzk0NDU1LDAuODMwMDc2IDAuODE3MjYxLDAuMjYxMjgxIDEu%0D%0ANjQwNDA3LDAuNTAzMTI3IDIuNDY3NzE4LDAuNzMzNDYzIDAuNzg1Mjg3LDAuMjA4MDMzIDEuNTc2%0D%0AMzA0LDAuMzk0ODMgMi4zNjYwODUsMC41ODYzNzcgMC43MjkxMjEsMC4xOTcwODMgMS40NjUwMjks%0D%0AMC4zNjQ1NDkgMi4yMDYxNSwwLjUxNDg3IDAuNzE3MjU4LDAuMTI5ODg0IDEuNDI5OTMyLDAuMjY2%0D%0ANTM0IDIuMTU2ODgsMC4zMzcxNDUgMC44NzA4NDYsMC4wNzg2NyAxLjczOTUxMiwwLjE2OTY2MSAy%0D%0ALjYxMjQwOCwwLjIyNjA5MyAxLjEwNDY3OSwwLjA4OTA1IDIuMjEwNTcsMC4wNDE3OCAzLjMxNjI0%0D%0ANSwwLjAwOTIgMS40MjE1MTEsLTAuMDMyNTggMi44NDEyNTIsLTAuMDc4NjMgNC4yNjA5NjgsLTAu%0D%0AMTU2MTMgMS4zNzU2MjUsLTAuMDg1NDUgMi43NDYwMTYsLTAuMjM4NzU3IDQuMTAxNTY5LC0wLjQ3%0D%0ANzc4OSAxLjE1NTg3NSwtMC4yNTkwNjYgMi4yOTYxNTYsLTAuNTg2MTc4IDMuNDA3Njg1LC0wLjk4%0D%0ANDQxMSAxLjA4NTQ2NywtMC40MTc5NiAyLjE0NDA5MywtMC44OTM2NTIgMy4xOTgzODcsLTEuMzc3%0D%0AOTM2IDAuODkxNzY4LC0wLjQyMjYwMyAxLjc1MzMyOSwtMC45MDU0OTEgMi42MDkxODgsLTEuMzkx%0D%0AMTYgMC4zODg2MjUsLTAuMjU1OTQzIDAuODUxOTg4LC0wLjQ2OTkxNSAxLjA2Mzc5NywtMC44OTAz%0D%0AMzcgLTAuNTcxNjg4LC0zLjAzNTI2OCAtMC4wOTExNiwyLjQxODQzOSAtMC4wNjcwMSw3LjM0NTEw%0D%0ANyAwLjE3NjI4NSwtMC4zMTcwMDggLTAuMjc4NzI3LC0wLjUzODE0NiAtMC41MTU2MjUsLTAuNjgw%0D%0AMzIzIDAsMCAwLjQ0MTU4NiwtNy44Mzk3MyAwLjQ0MTU4NiwtNy44Mzk3MyBsIDAsMCBjIDAuMzk2%0D%0AOTMzLDAuMjE0MzM2IDAuODExNzY3LDAuMzk5MTE2IDEuMTgxNDIsMC42NTcwODIgMC4wMjM4OSwy%0D%0ALjM1NTExMyAxLjk1NTU1NCw2LjQ3NjcxNCAtMC4zMzgwODUsOC4zOTM5NjMgLTAuNDIxOTI0LDAu%0D%0AMzAxNjkzIC0wLjg5NDMxMSwwLjUzMDUxOCAtMS4zNTczNjQsMC43Njc4NjggLTAuODg5NjI5LDAu%0D%0ANDMxNTIgLTEuNzUyMTgzLDAuOTEzMzIgLTIuNjYzNTU5LDEuMzAzMDA5IC0xLjA3ODIzMywwLjQ3%0D%0ANzc4MiAtMi4xNTA0NTIsMC45Njg4MyAtMy4yNjgwMzYsMS4zNTk2OTYgLTEuMTU3MDY3LDAuNDA2%0D%0AMzU0IC0yLjMzOTQ5MiwwLjc2MTAyNyAtMy41NTQzOTYsMC45NzE0NjggLTEuMzg5NjYsMC4yMTg0%0D%0ANzYgLTIuNzkyMDc2LDAuMzM2NjI1IC00LjE5NjcxOSwwLjQyODE4NiAtMS40MjE1NzMsMC4wNjkw%0D%0ANCAtMi44NDE2OTMsMC4xNjAxMzIgLTQuMjY0MjU1LDAuMjExMzMzIC0xLjEzMjU1NywwLjA3MzYx%0D%0AIC0yLjI2NDc1NSwwLjE0MTE1MSAtMy40MDA0MywwLjA3OTkgLTAuODgzODE5LC0wLjAzNjQ1IC0x%0D%0ALjc2MjA3OCwtMC4xMjg4MjkgLTIuNjQ0NzA4LC0wLjE3NjMzMSAtMC43NTc1NjYsLTAuMDYzOTIg%0D%0ALTEuNTAzNjA2LC0wLjE4MjI5MyAtMi4yNDQ5NzMsLTAuMzQ0NzIzIC0wLjc2MDc2MSwtMC4xNDQ4%0D%0AMTcgLTEuNTE4MiwtMC4zMDIwNDcgLTIuMjYyMDExLC0wLjUxNDA1MyAtMC43ODQ1MTgsLTAuMjI4%0D%0AMjQ1IC0xLjU4OTkwNywtMC4zODY3NSAtMi4zNzc5NywtMC42MDQyMjggLTAuODMxOTQyLC0wLjIz%0D%0ANjk4OCAtMS42NjI4OTIsLTAuNDc1MTk1IC0yLjQ4MzUyMywtMC43NDY1IC0wLjgxNTk1NSwtMC4y%0D%0ANDA5NDEgLTEuNjI0ODcxLC0wLjUwMjcxOSAtMi40MTQxNDYsLTAuODE1MTI1IC0wLjg0NDk4MSwt%0D%0AMC4yOTAxNzMgLTEuNzAwMzY3LC0wLjU0NjU4NCAtMi41NTIzMzIsLTAuODE1Mjk1IC0wLjg4NTYy%0D%0AMywtMC4yNzA3NTkgLTEuNzg5MjUsLTAuNDg0MzM5IC0yLjY4OTI5MywtMC43MDYzNjUgLTAuOTEx%0D%0ANTU4LC0wLjIzMzAwMyAtMS44MjYwOTUsLTAuNDUyMDEzIC0yLjc0MzYwOCwtMC42NjE3NzQgLTAu%0D%0AODYwODI0LC0wLjE4Nzg5MiAtMS43MjE2NjIsLTAuMzc4NDQxIC0yLjU5ODk2OCwtMC40ODQxMzEg%0D%0ALTAuNzY2NTk5LC0wLjE0NjU4NCAtMS41MzI4NzksLTAuMjkxNTUxIC0yLjMwODMyLC0wLjM5MDE3%0D%0AOCAtMC42MzU4ODksLTAuMTAzMDY3IC0xLjI3NzA4MywtMC4xODM1NDEgLTEuOTE5MjQ1LC0wLjI0%0D%0AMDYxNCAtMC41MjQyNjEsLTAuMDU0MDEgLTEuMDQ3ODg1LC0wLjA2NTUzIC0xLjU3NTU5OSwtMC4w%0D%0ANTA2MyAtMC41OTUxOTEsLTAuMDAyNyAtMS4xOTI1MjksMC4wMDczIC0xLjc4MzkxNiwwLjA3NjY3%0D%0AIC0wLjcyMzU5NywwLjA5MzIyIC0xLjQzNDM5NiwwLjI1OTg5OSAtMi4xNDE2MTksMC40MzAyNzQg%0D%0ALTAuNzE2MTUsMC4yMDE0NzEgLTEuNDMyNzQ1LDAuNDA4MTc0IC0yLjEwNTcyLDAuNzIyNDc5IC0w%0D%0ALjcwMDM5MywwLjMxOTg1OSAtMS4zNzM4MjcsMC42ODI4NjkgLTEuOTk1MjQxLDEuMTMwNjUzIC0w%0D%0ALjU5NjMzLDAuNDM4MTE4IC0xLjE3MzQxNSwwLjkwMDc1NiAtMS43MjE3MTIsMS4zOTMwODYgLTAu%0D%0ANDQzMjI1LDAuNDE2ODkzIC0wLjkxNzAxOCwwLjgwNDU4MSAtMS4zMDQwODcsMS4yNzMxOTIgLTAu%0D%0AMzY5NDYzLDAuNDI4NzYgLTAuNjk5OTQxLDAuODgxOTcgLTEuMDI3NDczLDEuMzQwMDk5IDAsMCAt%0D%0AMC43NDAxOCwtNy44Njk2MTggLTAuNzQwMTgsLTcuODY5NjE4IHoiCiAgICAgICBpbmtzY2FwZTpj%0D%0Ab25uZWN0b3ItY3VydmF0dXJlPSIwIiAvPgogICAgPHBhdGgKICAgICAgIHN0eWxlPSJjb2xvcjoj%0D%0AMDAwMDAwO2NsaXAtcnVsZTpub256ZXJvO2Rpc3BsYXk6aW5saW5lO292ZXJmbG93OnZpc2libGU7%0D%0AdmlzaWJpbGl0eTp2aXNpYmxlO29wYWNpdHk6MTtpc29sYXRpb246YXV0bzttaXgtYmxlbmQtbW9k%0D%0AZTpub3JtYWw7Y29sb3ItaW50ZXJwb2xhdGlvbjpzUkdCO2NvbG9yLWludGVycG9sYXRpb24tZmls%0D%0AdGVyczpsaW5lYXJSR0I7c29saWQtY29sb3I6IzAwMDAwMDtzb2xpZC1vcGFjaXR5OjE7ZmlsbDoj%0D%0AZmZmZmQzO2ZpbGwtb3BhY2l0eToxO2ZpbGwtcnVsZTpub256ZXJvO3N0cm9rZTojMzAzYzQyO3N0%0D%0Acm9rZS13aWR0aDowO3N0cm9rZS1saW5lY2FwOnJvdW5kO3N0cm9rZS1saW5lam9pbjpyb3VuZDtz%0D%0AdHJva2UtbWl0ZXJsaW1pdDo0O3N0cm9rZS1kYXNoYXJyYXk6bm9uZTtzdHJva2UtZGFzaG9mZnNl%0D%0AdDowO3N0cm9rZS1vcGFjaXR5OjE7Y29sb3ItcmVuZGVyaW5nOmF1dG87aW1hZ2UtcmVuZGVyaW5n%0D%0AOmF1dG87c2hhcGUtcmVuZGVyaW5nOmF1dG87dGV4dC1yZW5kZXJpbmc6YXV0bztlbmFibGUtYmFj%0D%0Aa2dyb3VuZDphY2N1bXVsYXRlIgogICAgICAgaWQ9InBhdGg0MjM0LTMiCiAgICAgICBkPSJtIDI5%0D%0ALjcxMDkzNiw2OS45NzUxMjEgYyAwLjMxMDQ3NywtMC40NTE3MTggMC42ODcxNjQsLTAuODU5Mjc0%0D%0AIDEuMDY0MDc5LC0xLjI2MTAwMiAwLjI1NTg5NCwtMC4zMjYyMDEgMC42MTAzOTksLTAuNTUxMDc0%0D%0AIDAuOTE4MTgsLTAuODI1MDM5IDAuNzg5ODgxLC0wLjcwMzA5NCAtMC40MjAxMDgsMC4zMTU3NjMg%0D%0AMC40ODA2NjQsLTAuNDMzMjg3IDAuNTg2OTAyLC0wLjQ3ODM3IDEuMTgzODM0LC0wLjk0OTgwNCAx%0D%0ALjgxOTk3MiwtMS4zNjgwODYgMC42NjA0NDEsLTAuNDcyMDU3IDEuNDAyNzk4LC0wLjc5NDQ2NSAy%0D%0ALjEzMjY2NiwtMS4xNDk0OTkgMC43MjEwODksLTAuMzE3OTY2IDEuNDg4NTIyLC0wLjUxMTczNSAy%0D%0ALjI0OTI4NCwtMC43MTkyNDEgMC43NDM1MzUsLTAuMTg4NTE0IDEuNDkyODcxLC0wLjM0MjYwNCAy%0D%0ALjI1MjU0OCwtMC40NTY2OTYgMC42Mjc1NTksLTAuMDgyMTQgMS4yNTk2MzMsLTAuMTAzMDU2IDEu%0D%0AODkxODAyLC0wLjEyMTQyMyAwLjU2NDA1MiwtMC4wMTE3OCAxLjEyMzI0NSwtMC4wMTE0NiAxLjY4%0D%0AMzI5OCwwLjA1NzUyIDAuNjU4NzQxLDAuMDY4NDYgMS4zMTI4MzMsMC4xNzA1MzkgMS45NjQ2NjQs%0D%0AMC4yODQyNDcgMC43Nzk2MDcsMC4xMjA0MzQgMS41NTQ3ODMsMC4yNjExMzggMi4zMjgzOTEsMC40%0D%0AMTI1NSAwLjg4MTc3NywwLjEzNzI3MSAxLjc1MTY1NCwwLjMyMDUwOCAyLjYyMDc5NiwwLjUxNTM3%0D%0AOCAwLjkyNzA4MywwLjIwOTA0NSAxLjg0NzQzLDAuNDQyMjQ5IDIuNzY4NzMsMC42NzMwODYgMC45%0D%0AMTIyNTgsMC4yMTI0MDQgMS44MjE1MzYsMC40NDAyMjggMi43MjE4NTIsMC42OTUzMDIgMC44NTQ3%0D%0AOTcsMC4yNzgyMyAxLjcyMDQwNCwwLjUyNDQ5IDIuNTc4NjYxLDAuNzkyMzU3IDAuNzk2NjQxLDAu%0D%0AMjgxMjc1IDEuNTg2MjkxLDAuNTc5NDUxIDIuMzk0NDU1LDAuODMwMDc2IDAuODE3MjYxLDAuMjYx%0D%0AMjgxIDEuNjQwNDA3LDAuNTAzMTI3IDIuNDY3NzE4LDAuNzMzNDYzIDAuNzg1Mjg3LDAuMjA4MDMz%0D%0AIDEuNTc2MzA0LDAuMzk0ODMgMi4zNjYwODYsMC41ODYzNzYgMC43MjkxMiwwLjE5NzA4NCAxLjQ2%0D%0ANTAyOCwwLjM2NDU1IDIuMjA2MTQ5LDAuNTE0ODcxIDAuNzE3MjU5LDAuMTI5ODg0IDEuNDI5OTMy%0D%0ALDAuMjY2NTMzIDIuMTU2ODgsMC4zMzcxNDUgMC44NzA4NDYsMC4wNzg2NyAxLjczOTUxMiwwLjE2%0D%0AOTY2MSAyLjYxMjQwOCwwLjIyNjA5MyAxLjEwNDY4LDAuMDg5MDUgMi4yMTA1NzEsMC4wNDE3OCAz%0D%0ALjMxNjI0NSwwLjAwOTIgMS40MjE1MTEsLTAuMDMyNTggMi44NDEyNTIsLTAuMDc4NjMgNC4yNjA5%0D%0ANjgsLTAuMTU2MTMxIDEuMzc1NjI1LC0wLjA4NTQ1IDIuNzQ2MDE2LC0wLjIzODc1NyA0LjEwMTU2%0D%0AOSwtMC40Nzc3ODggMS4xNTU4NzUsLTAuMjU5MDY2IDIuMjk2MTU2LC0wLjU4NjE3OCAzLjQwNzY4%0D%0ANSwtMC45ODQ0MTEgMS4wODU0NjcsLTAuNDE3OTYxIDIuMTQ0MDkzLC0wLjg5MzY1MiAzLjE5ODM4%0D%0ANywtMS4zNzc5MzYgMC44OTE3NjgsLTAuNDIyNjAzIDEuNzUzMzI5LC0wLjkwNTQ5MSAyLjYwOTE4%0D%0AOCwtMS4zOTExNiAwLjM4ODYyNiwtMC4yNTU5NDMgMC44NTE5ODYsLTAuNDY5OTE1IDEuMDYzNzk4%0D%0ALC0wLjg5MDMzNyAtMC41NzE2OSwtMy4wMzUyNjggLTAuMDkxMTUsMi40MTg0MzggLTAuMDY2OTcs%0D%0ANy4zNDUxMDcgMC4xNzYyNzgsLTAuMzE3MDA4IC0wLjI3ODcyNSwtMC41MzgxNDYgLTAuNTE1NjMs%0D%0ALTAuNjgwMzIzIDAsMCAwLjQ0MTU4NywtNy44Mzk3MyAwLjQ0MTU4NywtNy44Mzk3MyBsIDAsMCBj%0D%0AIDAuMzk2OTM4LDAuMjE0MzM2IDAuODExNzcxLDAuMzk5MTE2IDEuMTgxNDIxLDAuNjU3MDgyIDAu%0D%0AMDIzODQsMi4zNTUxMTMgMS45NTU1NTIsNi40NzY3MTQgLTAuMzM4MDgyLDguMzkzOTYzIC0wLjQy%0D%0AMTkyMSwwLjMwMTY5MyAtMC44OTQzMTcsMC41MzA1MTggLTEuMzU3MzY1LDAuNzY3ODY4IC0wLjg4%0D%0AOTYzLDAuNDMxNTIgLTEuNzUyMTgzLDAuOTEzMzIgLTIuNjYzNTYsMS4zMDMwMDkgLTEuMDc4MjMy%0D%0ALDAuNDc3NzgyIC0yLjE1MDQ1MSwwLjk2ODgzIC0zLjI2ODAzNSwxLjM1OTY5NiAtMS4xNTcwNjcs%0D%0AMC40MDYzNTQgLTIuMzM5NDkyLDAuNzYxMDI3IC0zLjU1NDM5NiwwLjk3MTQ2OCAtMS4zODk2Niww%0D%0ALjIxODQ3NiAtMi43OTIwNzcsMC4zMzY2MjUgLTQuMTk2NzE5LDAuNDI4MTg2IC0xLjQyMTU3Myww%0D%0ALjA2OTA0IC0yLjg0MTY5MywwLjE2MDEzMSAtNC4yNjQyNTUsMC4yMTEzMzMgLTEuMTMyNTU3LDAu%0D%0AMDczNjEgLTIuMjY0NzU1LDAuMTQxMTUgLTMuNDAwNDMsMC4wNzk5IC0wLjg4MzgyLC0wLjAzNjQ1%0D%0AIC0xLjc2MjA3OCwtMC4xMjg4MjkgLTIuNjQ0NzA4LC0wLjE3NjMzMSAtMC43NTc1NjcsLTAuMDYz%0D%0AOTIgLTEuNTAzNjA2LC0wLjE4MjI5NCAtMi4yNDQ5NzMsLTAuMzQ0NzIzIC0wLjc2MDc2MSwtMC4x%0D%0ANDQ4MTcgLTEuNTE4MjAxLC0wLjMwMjA0OCAtMi4yNjIwMTEsLTAuNTE0MDUzIC0wLjc4NDUxOCwt%0D%0AMC4yMjgyNDUgLTEuNTg5OTA3LC0wLjM4Njc1IC0yLjM3Nzk3LC0wLjYwNDIyOCAtMC44MzE5NDIs%0D%0ALTAuMjM2OTg4IC0xLjY2Mjg5MiwtMC40NzUxOTUgLTIuNDgzNTIzLC0wLjc0NjUgLTAuODE1OTU1%0D%0ALC0wLjI0MDk0MiAtMS42MjQ4NzIsLTAuNTAyNzIgLTIuNDE0MTQ2LC0wLjgxNTEyNSAtMC44NDQ5%0D%0ANzksLTAuMjkwMjE0IC0xLjcwMDM2NiwtMC41NDY2MjUgLTIuNTUyMzMsLTAuODE1MzM2IEMgNTUu%0D%0ANDgwMzQsNzMuNzQxMjUzIDU0LjU3NjcxNCw3My41Mjc2NzMgNTMuNjc2NjcxLDczLjMwNTY0NyA1%0D%0AMi43NjUxMTIsNzMuMDcyNjQ0IDUxLjg1MDU3Niw3Mi44NTM2MzQgNTAuOTMzMDYzLDcyLjY0Mzg3%0D%0AMyA1MC4wNzIyMzksNzIuNDU1OTgxIDQ5LjIxMTQsNzIuMjY1NDMyIDQ4LjMzNDA5NSw3Mi4xNTk3%0D%0ANDIgNDcuNTY3NDk2LDcyLjAxMzE1OCA0Ni44MDEyMTYsNzEuODY4MTkgNDYuMDI1Nzc0LDcxLjc2%0D%0AOTU2NCA0NS4zODk4ODYsNzEuNjY2NDk3IDQ0Ljc0ODY5Miw3MS41ODYwMjMgNDQuMTA2NTMsNzEu%0D%0ANTI4OTUgYyAtMC41MjQyNjEsLTAuMDU0MDEgLTEuMDQ3ODg2LC0wLjA2NTU0IC0xLjU3NTU5OSwt%0D%0AMC4wNTA2MyAtMC41OTUxOTEsLTAuMDAyNyAtMS4xOTI1MywwLjAwNzMgLTEuNzgzOTE3LDAuMDc2%0D%0ANjcgLTAuNzIzNTk2LDAuMDkzMjIgLTEuNDM0Mzk1LDAuMjU5ODk5IC0yLjE0MTYxOCwwLjQzMDI3%0D%0ANCAtMC43MTYxNSwwLjIwMTQ3MSAtMS40MzI3NDYsMC40MDgxNzMgLTIuMTA1NzIxLDAuNzIyNDc5%0D%0AIC0wLjcwMDM5MywwLjMxOTg1OSAtMS4zNzM4MjYsMC42ODI4NjkgLTEuOTk1MjQsMS4xMzA2NTMg%0D%0ALTAuNTk2MzMsMC40MzgxMTggLTEuMTczNDE1LDAuOTAwNzU2IC0xLjcyMTcxMiwxLjM5MzA4NiAt%0D%0AMC40NDMyMjUsMC40MTY4OTMgLTAuOTE3MDE4LDAuODA0NTgxIC0xLjMwNDA4NywxLjI3MzE5MiAt%0D%0AMC4zNjk0NjMsMC40Mjg3NiAtMC42OTk5NDIsMC44ODE5NyAtMS4wMjc0NzMsMS4zNDAwOTkgMCww%0D%0AIC0wLjc0MDE4LC03Ljg2OTYxOCAtMC43NDAxOCwtNy44Njk2MTggeiIKICAgICAgIGlua3NjYXBl%0D%0AOmNvbm5lY3Rvci1jdXJ2YXR1cmU9IjAiIC8+CiAgICA8cGF0aAogICAgICAgc3R5bGU9ImNvbG9y%0D%0AOiMwMDAwMDA7Y2xpcC1ydWxlOm5vbnplcm87ZGlzcGxheTppbmxpbmU7b3ZlcmZsb3c6dmlzaWJs%0D%0AZTt2aXNpYmlsaXR5OnZpc2libGU7b3BhY2l0eToxO2lzb2xhdGlvbjphdXRvO21peC1ibGVuZC1t%0D%0Ab2RlOm5vcm1hbDtjb2xvci1pbnRlcnBvbGF0aW9uOnNSR0I7Y29sb3ItaW50ZXJwb2xhdGlvbi1m%0D%0AaWx0ZXJzOmxpbmVhclJHQjtzb2xpZC1jb2xvcjojMDAwMDAwO3NvbGlkLW9wYWNpdHk6MTtmaWxs%0D%0AOiNmZmZmODI7ZmlsbC1vcGFjaXR5OjE7ZmlsbC1ydWxlOm5vbnplcm87c3Ryb2tlOiMzMDNjNDI7%0D%0Ac3Ryb2tlLXdpZHRoOjA7c3Ryb2tlLWxpbmVjYXA6cm91bmQ7c3Ryb2tlLWxpbmVqb2luOnJvdW5k%0D%0AO3N0cm9rZS1taXRlcmxpbWl0OjQ7c3Ryb2tlLWRhc2hhcnJheTpub25lO3N0cm9rZS1kYXNob2Zm%0D%0Ac2V0OjA7c3Ryb2tlLW9wYWNpdHk6MTtjb2xvci1yZW5kZXJpbmc6YXV0bztpbWFnZS1yZW5kZXJp%0D%0Abmc6YXV0bztzaGFwZS1yZW5kZXJpbmc6YXV0bzt0ZXh0LXJlbmRlcmluZzphdXRvO2VuYWJsZS1i%0D%0AYWNrZ3JvdW5kOmFjY3VtdWxhdGUiCiAgICAgICBpZD0icGF0aDQyMzQtMy02IgogICAgICAgZD0i%0D%0AbSAzNi4zMDAyMTQsODYuNTE2Nzg2IGMgMC4zMTA0NzcsLTAuNDUxNzE4IDAuNjg3MTY1LC0wLjg1%0D%0AOTI3NCAxLjA2NDA3OSwtMS4yNjEwMDIgMC4yNTU4OTUsLTAuMzI2MjAxIDAuNjEwMzk5LC0wLjU1%0D%0AMTA3NCAwLjkxODE4MSwtMC44MjUwNCAwLjc4OTg4LC0wLjcwMzA5MyAtMC40MjAxMDksMC4zMTU3%0D%0ANjQgMC40ODA2NjMsLTAuNDMzMjg2IDAuNTg2OTAyLC0wLjQ3ODM3IDEuMTgzODM1LC0wLjk0OTgw%0D%0ANCAxLjgxOTk3MiwtMS4zNjgwODYgMC42NjA0NDIsLTAuNDcyMDU3IDEuNDAyNzk4LC0wLjc5NDQ2%0D%0ANiAyLjEzMjY2NiwtMS4xNDk0OTkgMC43MjEwOSwtMC4zMTc5NjYgMS40ODg1MjIsLTAuNTExNzM1%0D%0AIDIuMjQ5Mjg0LC0wLjcxOTI0MSAwLjc0MzUzNiwtMC4xODg1MTQgMS40OTI4NzEsLTAuMzQyNjA0%0D%0AIDIuMjUyNTQ4LC0wLjQ1NjY5NiAwLjYyNzU2LC0wLjA4MjE0IDEuMjU5NjMzLC0wLjEwMzA1NiAx%0D%0ALjg5MTgwMywtMC4xMjE0MjQgMC41NjQwNTEsLTAuMDExNzggMS4xMjMyNDQsLTAuMDExNDYgMS42%0D%0AODMyOTgsMC4wNTc1MiAwLjY1ODc0LDAuMDY4NDYgMS4zMTI4MzMsMC4xNzA1MzkgMS45NjQ2NjMs%0D%0AMC4yODQyNDYgMC43Nzk2MDcsMC4xMjA0MzUgMS41NTQ3ODQsMC4yNjExMzkgMi4zMjgzOTEsMC40%0D%0AMTI1NTEgMC44ODE3NzcsMC4xMzcyNzEgMS43NTE2NTUsMC4zMjA1MDggMi42MjA3OTcsMC41MTUz%0D%0ANzggMC45MjcwODIsMC4yMDkwNDUgMS44NDc0MywwLjQ0MjI0OSAyLjc2ODczLDAuNjczMDg2IDAu%0D%0AOTEyMjU4LDAuMjEyNDA0IDEuODIxNTM1LDAuNDQwMjI3IDIuNzIxODUxLDAuNjk1MzAyIDAuODU0%0D%0ANzk3LDAuMjc4MjMgMS43MjA0MDUsMC41MjQ0OSAyLjU3ODY2MiwwLjc5MjM1NyAwLjc5NjY0LDAu%0D%0AMjgxMjc1IDEuNTg2MjksMC41Nzk0NTEgMi4zOTQ0NTUsMC44MzAwNzYgMC44MTcyNiwwLjI2MTI4%0D%0AMSAxLjY0MDQwNiwwLjUwMzEyNyAyLjQ2NzcxNywwLjczMzQ2MyAwLjc4NTI4OCwwLjIwODAzMyAx%0D%0ALjU3NjMwNSwwLjM5NDgzIDIuMzY2MDg2LDAuNTg2Mzc2IDAuNzI5MTIsMC4xOTcwODQgMS40NjUw%0D%0AMjksMC4zNjQ1NSAyLjIwNjE0OSwwLjUxNDg3MSAwLjcxNzI1OSwwLjEyOTg4NCAxLjQyOTkzMyww%0D%0ALjI2NjUzMyAyLjE1Njg4MSwwLjMzNzE0NSAwLjg3MDg0NiwwLjA3ODY3IDEuNzM5NTExLDAuMTY5%0D%0ANjYxIDIuNjEyNDA3LDAuMjI2MDkzIDEuMTA0NjgsMC4wODkwNSAyLjIxMDU3MSwwLjA0MTc4IDMu%0D%0AMzE2MjQ2LDAuMDA5MiAxLjQyMTUxLC0wLjAzMjU4IDIuODQxMjUxLC0wLjA3ODYzIDQuMjYwOTY4%0D%0ALC0wLjE1NjEzMSAxLjM3NTYyNCwtMC4wODU0NSAyLjc0NjAxNSwtMC4yMzg3NTcgNC4xMDE1Njgs%0D%0ALTAuNDc3Nzg4IDEuMTU1ODc2LC0wLjI1OTA2NiAyLjI5NjE1NywtMC41ODYxNzkgMy40MDc2ODYs%0D%0ALTAuOTg0NDExIDEuMDg1NDY2LC0wLjQxNzk2MSAyLjE0NDA5MSwtMC44OTM2NTIgMy4xOTgzODQs%0D%0ALTEuMzc3OTM2IDAuODkxNzY1LC0wLjQyMjYwMyAxLjc1MzMzMSwtMC45MDU0OTIgMi42MDkxOTEs%0D%0ALTEuMzkxMTYgMC4zODg2MiwtMC4yNTU5NDMgMC44NTE5OCwtMC40Njk5MTUgMS4wNjM3OSwtMC44%0D%0AOTAzMzggLTAuNTcxNjksLTMuMDM1MjY3IC0wLjA5MTEsMi40MTg0MzkgLTAuMDY3LDcuMzQ1MTA4%0D%0AIDAuMTc2MjgsLTAuMzE3MDA4IC0wLjI3ODcyLC0wLjUzODE0NiAtMC41MTU2MywtMC42ODAzMjMg%0D%0AMCwwIDAuNDQxNTksLTcuODM5NzMxIDAuNDQxNTksLTcuODM5NzMxIGwgMCwwIGMgMC4zOTY5NCww%0D%0ALjIxNDMzNyAwLjgxMTc3LDAuMzk5MTE3IDEuMTgxNDIsMC42NTcwODMgMC4wMjM4LDIuMzU1MTEz%0D%0AIDEuOTU1NTYsNi40NzY3MTQgLTAuMzM4MDgsOC4zOTM5NjMgLTAuNDIxOTIsMC4zMDE2OTMgLTAu%0D%0AODk0MzIsMC41MzA1MTggLTEuMzU3MzcsMC43Njc4NjggLTAuODg5NjIsMC40MzE1MiAtMS43NTIx%0D%0ANzEsMC45MTMzMiAtMi42NjM1NDgsMS4zMDMwMDkgLTEuMDc4MjM5LDAuNDc3NzgyIC0yLjE1MDQ1%0D%0ANCwwLjk2ODgzIC0zLjI2ODAzOSwxLjM1OTY5NiAtMS4xNTcwNjcsMC40MDYzNTQgLTIuMzM5NDky%0D%0ALDAuNzYxMDI3IC0zLjU1NDM5NiwwLjk3MTQ2OCAtMS4zODk2NiwwLjIxODQ3NSAtMi43OTIwNzYs%0D%0AMC4zMzY2MjUgLTQuMTk2NzE5LDAuNDI4MTg2IC0xLjQyMTU3MywwLjA2OTA0IC0yLjg0MTY5Miww%0D%0ALjE2MDEzMSAtNC4yNjQyNTUsMC4yMTEzMzIgLTEuMTMyNTU2LDAuMDczNjIgLTIuMjY0NzU0LDAu%0D%0AMTQxMTUxIC0zLjQwMDQzLDAuMDc5OSAtMC44ODM4MTksLTAuMDM2NDUgLTEuNzYyMDc3LC0wLjEy%0D%0AODgyOCAtMi42NDQ3MDgsLTAuMTc2MzMgLTAuNzU3NTY2LC0wLjA2MzkyIC0xLjUwMzYwNiwtMC4x%0D%0AODIyOTQgLTIuMjQ0OTczLC0wLjM0NDcyMyAtMC43NjA3NjEsLTAuMTQ0ODE3IC0xLjUxODIsLTAu%0D%0AMzAyMDQ4IC0yLjI2MjAxMSwtMC41MTQwNTMgLTAuNzg0NTE3LC0wLjIyODI0NSAtMS41ODk5MDYs%0D%0ALTAuMzg2NzUgLTIuMzc3OTY5LC0wLjYwNDIyOCAtMC44MzE5NDIsLTAuMjM2OTg4IC0xLjY2Mjg5%0D%0AMywtMC40NzUxOTUgLTIuNDgzNTI0LC0wLjc0NjUwMSAtMC44MTU5NTQsLTAuMjQwOTQxIC0xLjYy%0D%0ANDg3MSwtMC41MDI3MTkgLTIuNDE0MTQ1LC0wLjgxNTEyNCAtMC44NDQ5ODIsLTAuMjkwMTczIC0x%0D%0ALjcwMDM2OCwtMC41NDY1ODQgLTIuNTUyMzMzLC0wLjgxNTI5NSAtMC44ODU2MjMsLTAuMjcwNzU5%0D%0AIC0xLjc4OTI1LC0wLjQ4NDMzOSAtMi42ODkyOTMsLTAuNzA2MzY1IC0wLjkxMTU1OCwtMC4yMzMw%0D%0AMDMgLTEuODI2MDk1LC0wLjQ1MjAxMyAtMi43NDM2MDgsLTAuNjYxNzc0IC0wLjg2MDgyNCwtMC4x%0D%0AODc4OTIgLTEuNzIxNjYyLC0wLjM3ODQ0MSAtMi41OTg5NjgsLTAuNDg0MTMxIC0wLjc2NjU5OCwt%0D%0AMC4xNDY1ODQgLTEuNTMyODc4LC0wLjI5MTU1MiAtMi4zMDgzMiwtMC4zOTAxNzkgLTAuNjM1ODg5%0D%0ALC0wLjEwMzA2NiAtMS4yNzcwODMsLTAuMTgzNTQxIC0xLjkxOTI0NSwtMC4yNDA2MTMgLTAuNTI0%0D%0AMjYxLC0wLjA1NDAxIC0xLjA0Nzg4NSwtMC4wNjU1NCAtMS41NzU1OTksLTAuMDUwNjMgLTAuNTk1%0D%0AMTkxLC0wLjAwMjcgLTEuMTkyNTI5LDAuMDA3MyAtMS43ODM5MTYsMC4wNzY2NyAtMC43MjM1OTcs%0D%0AMC4wOTMyMiAtMS40MzQzOTYsMC4yNTk5IC0yLjE0MTYxOCwwLjQzMDI3NSAtMC43MTYxNSwwLjIw%0D%0AMTQ3MSAtMS40MzI3NDYsMC40MDgxNzMgLTIuMTA1NzIxLDAuNzIyNDc5IC0wLjcwMDM5MywwLjMx%0D%0AOTg1OSAtMS4zNzM4MjYsMC42ODI4NjggLTEuOTk1MjQxLDEuMTMwNjUyIC0wLjU5NjMzLDAuNDM4%0D%0AMTE5IC0xLjE3MzQxNSwwLjkwMDc1NiAtMS43MjE3MTEsMS4zOTMwODcgLTAuNDQzMjI2LDAuNDE2%0D%0AODkzIC0wLjkxNzAxOSwwLjgwNDU4IC0xLjMwNDA4OCwxLjI3MzE5MiAtMC4zNjk0NjMsMC40Mjg3%0D%0ANiAtMC42OTk5NDEsMC44ODE5NyAtMS4wMjc0NzIsMS4zNDAwOTkgMCwwIC0wLjc0MDE4MSwtNy44%0D%0ANjk2MTggLTAuNzQwMTgxLC03Ljg2OTYxOCB6IgogICAgICAgaW5rc2NhcGU6Y29ubmVjdG9yLWN1%0D%0AcnZhdHVyZT0iMCIgLz4KICAgIDxwYXRoCiAgICAgICBzdHlsZT0iY29sb3I6IzAwMDAwMDtjbGlw%0D%0ALXJ1bGU6bm9uemVybztkaXNwbGF5OmlubGluZTtvdmVyZmxvdzp2aXNpYmxlO3Zpc2liaWxpdHk6%0D%0AdmlzaWJsZTtvcGFjaXR5OjE7aXNvbGF0aW9uOmF1dG87bWl4LWJsZW5kLW1vZGU6bm9ybWFsO2Nv%0D%0AbG9yLWludGVycG9sYXRpb246c1JHQjtjb2xvci1pbnRlcnBvbGF0aW9uLWZpbHRlcnM6bGluZWFy%0D%0AUkdCO3NvbGlkLWNvbG9yOiMwMDAwMDA7c29saWQtb3BhY2l0eToxO2ZpbGw6I2ZmZmY3OTtmaWxs%0D%0ALW9wYWNpdHk6MTtmaWxsLXJ1bGU6bm9uemVybztzdHJva2U6IzMwM2M0MjtzdHJva2Utd2lkdGg6%0D%0AMDtzdHJva2UtbGluZWNhcDpyb3VuZDtzdHJva2UtbGluZWpvaW46cm91bmQ7c3Ryb2tlLW1pdGVy%0D%0AbGltaXQ6NDtzdHJva2UtZGFzaGFycmF5Om5vbmU7c3Ryb2tlLWRhc2hvZmZzZXQ6MDtzdHJva2Ut%0D%0Ab3BhY2l0eToxO2NvbG9yLXJlbmRlcmluZzphdXRvO2ltYWdlLXJlbmRlcmluZzphdXRvO3NoYXBl%0D%0ALXJlbmRlcmluZzphdXRvO3RleHQtcmVuZGVyaW5nOmF1dG87ZW5hYmxlLWJhY2tncm91bmQ6YWNj%0D%0AdW11bGF0ZSIKICAgICAgIGlkPSJwYXRoNDIzNC03IgogICAgICAgZD0ibSAzNS4zMjgzNzMsNTEu%0D%0ANTQzNDM1IGMgMC4zMTA0NzcsLTAuNDUxNzE4IDAuNjg3MTY0LC0wLjg1OTI3NCAxLjA2NDA3OSwt%0D%0AMS4yNjEwMDIgMC4yNTU4OTQsLTAuMzI2MjAxIDAuNjEwMzk4LC0wLjU1MTA3NCAwLjkxODE4LC0w%0D%0ALjgyNTAzOSAwLjc4OTg4LC0wLjcwMzA5NCAtMC40MjAxMDgsMC4zMTU3NjMgMC40ODA2NjQsLTAu%0D%0ANDMzMjg3IDAuNTg2OTAyLC0wLjQ3ODM3IDEuMTgzODM0LC0wLjk0OTgwNCAxLjgxOTk3MSwtMS4z%0D%0ANjgwODYgMC42NjA0NDIsLTAuNDcyMDU3IDEuNDAyNzk5LC0wLjc5NDQ2NSAyLjEzMjY2NywtMS4x%0D%0ANDk0OTkgMC43MjEwODksLTAuMzE3OTY2IDEuNDg4NTIyLC0wLjUxMTczNSAyLjI0OTI4NCwtMC43%0D%0AMTkyNDEgMC43NDM1MzUsLTAuMTg4NTE0IDEuNDkyODcxLC0wLjM0MjYwMyAyLjI1MjU0NywtMC40%0D%0ANTY2OTYgMC42Mjc1NiwtMC4wODIxNCAxLjI1OTYzNCwtMC4xMDMwNTYgMS44OTE4MDMsLTAuMTIx%0D%0ANDIzIDAuNTY0MDUxLC0wLjAxMTc4IDEuMTIzMjQ1LC0wLjAxMTQ2IDEuNjgzMjk4LDAuMDU3NTIg%0D%0AMC42NTg3NCwwLjA2ODQ2IDEuMzEyODMzLDAuMTcwNTM5IDEuOTY0NjY0LDAuMjg0MjQ3IDAuNzc5%0D%0ANjA3LDAuMTIwNDM0IDEuNTU0NzgzLDAuMjYxMTM4IDIuMzI4MzkxLDAuNDEyNTUgMC44ODE3Nzcs%0D%0AMC4xMzcyNzEgMS43NTE2NTQsMC4zMjA1MDkgMi42MjA3OTYsMC41MTUzNzggMC45MjcwODMsMC4y%0D%0AMDkwNDUgMS44NDc0MywwLjQ0MjI0OSAyLjc2ODczLDAuNjczMDg2IDAuOTEyMjU4LDAuMjEyNDA0%0D%0AIDEuODIxNTM1LDAuNDQwMjI4IDIuNzIxODUyLDAuNjk1MzAyIDAuODU0Nzk3LDAuMjc4MjMgMS43%0D%0AMjA0MDQsMC41MjQ0OSAyLjU3ODY2MSwwLjc5MjM1NyAwLjc5NjY0MSwwLjI4MTI3NiAxLjU4NjI5%0D%0AMSwwLjU3OTQ1MSAyLjM5NDQ1NSwwLjgzMDA3NiAwLjgxNzI2MSwwLjI2MTI4MSAxLjY0MDQwNyww%0D%0ALjUwMzEyNyAyLjQ2NzcxOCwwLjczMzQ2MyAwLjc4NTI4NywwLjIwODAzMyAxLjU3NjMwNCwwLjM5%0D%0ANDgzIDIuMzY2MDg1LDAuNTg2Mzc2IDAuNzI5MTIxLDAuMTk3MDg0IDEuNDY1MDI5LDAuMzY0NTUg%0D%0AMi4yMDYxNSwwLjUxNDg3MSAwLjcxNzI1OCwwLjEyOTg4NCAxLjQyOTkzMiwwLjI2NjUzNCAyLjE1%0D%0ANjg4LDAuMzM3MTQ1IDAuODcwODQ2LDAuMDc4NjcgMS43Mzk1MTEsMC4xNjk2NjEgMi42MTI0MDgs%0D%0AMC4yMjYwOTMgMS4xMDQ2NzksMC4wODkwNSAyLjIxMDU3LDAuMDQxNzggMy4zMTYyNDUsMC4wMDky%0D%0AIDEuNDIxNTExLC0wLjAzMjU4IDIuODQxMjUyLC0wLjA3ODYzIDQuMjYwOTY4LC0wLjE1NjEzMSAx%0D%0ALjM3NTYyNSwtMC4wODU0NSAyLjc0NjAxNiwtMC4yMzg3NTcgNC4xMDE1NywtMC40Nzc3ODggMS4x%0D%0ANTU4NzEsLTAuMjU5MDY2IDIuMjk2MTUzLC0wLjU4NjE3OCAzLjQwNzY4NiwtMC45ODQ0MTEgMS4w%0D%0AODU0NiwtMC40MTc5NiAyLjE0NDA4OCwtMC44OTM2NTIgMy4xOTgzODEsLTEuMzc3OTM2IDAuODkx%0D%0ANzc3LC0wLjQyMjYwMyAxLjc1MzMzNywtMC45MDU0OTEgMi42MDkxOTcsLTEuMzkxMTYgMC4zODg2%0D%0AMjcsLTAuMjU1OTQzIDAuODUxOTg3LC0wLjQ2OTkxNSAxLjA2Mzc4NywtMC44OTAzMzcgLTAuNTcx%0D%0ANjgsLTMuMDM1MjY4IC0wLjA5MTEsMi40MTg0MzggLTAuMDY3LDcuMzQ1MTA3IDAuMTc2MjksLTAu%0D%0AMzE3MDA4IC0wLjI3ODczLC0wLjUzODE0NiAtMC41MTU2MiwtMC42ODAzMjMgMCwwIDAuNDQxNTks%0D%0ALTcuODM5NzMgMC40NDE1OSwtNy44Mzk3MyBsIDAsMCBjIDAuMzk2OTMsMC4yMTQzMzYgMC44MTE3%0D%0ANiwwLjM5OTExNiAxLjE4MTQyLDAuNjU3MDgyIDAuMDIzOCwyLjM1NTExMyAxLjk1NTU1LDYuNDc2%0D%0ANzE0IC0wLjMzODA5LDguMzkzOTYzIC0wLjQyMTkyLDAuMzAxNjkzIC0wLjg5NDMxLDAuNTMwNTE4%0D%0AIC0xLjM1NzM2LDAuNzY3ODY4IC0wLjg4OTYzNywwLjQzMTUyIC0xLjc1MjE4NywwLjkxMzMxOSAt%0D%0AMi42NjM1NjEsMS4zMDMwMDggLTEuMDc4MjM5LDAuNDc3NzgyIC0yLjE1MDQ1LDAuOTY4ODMgLTMu%0D%0AMjY4MDM0LDEuMzU5Njk2IC0xLjE1NzA3NCwwLjQwNjM1NCAtMi4zMzk0OTgsMC43NjEwMjcgLTMu%0D%0ANTU0NDAzLDAuOTcxNDY4IC0xLjM4OTY1NiwwLjIxODQ3NiAtMi43OTIwNzMsMC4zMzY2MjUgLTQu%0D%0AMTk2NzE1LDAuNDI4MTg2IC0xLjQyMTU3MywwLjA2OTA0IC0yLjg0MTY5MywwLjE2MDEzMSAtNC4y%0D%0ANjQyNTUsMC4yMTEzMzMgLTEuMTMyNTU3LDAuMDczNjEgLTIuMjY0NzU1LDAuMTQxMTUgLTMuNDAw%0D%0ANDMxLDAuMDc5OSAtMC44ODM4MTksLTAuMDM2NDUgLTEuNzYyMDc3LC0wLjEyODgyOSAtMi42NDQ3%0D%0AMDcsLTAuMTc2MzMxIC0wLjc1NzU2NywtMC4wNjM5MiAtMS41MDM2MDYsLTAuMTgyMjk0IC0yLjI0%0D%0ANDk3MywtMC4zNDQ3MjMgLTAuNzYwNzYxLC0wLjE0NDgxNyAtMS41MTgyMDEsLTAuMzAyMDQ4IC0y%0D%0ALjI2MjAxMiwtMC41MTQwNTMgLTAuNzg0NTE3LC0wLjIyODI0NSAtMS41ODk5MDYsLTAuMzg2NzUg%0D%0ALTIuMzc3OTY5LC0wLjYwNDIyOCAtMC44MzE5NDIsLTAuMjM2OTg4IC0xLjY2Mjg5MiwtMC40NzUx%0D%0AOTUgLTIuNDgzNTI0LC0wLjc0NjUgLTAuODE1OTU0LC0wLjI0MDk0MiAtMS42MjQ4NzEsLTAuNTAy%0D%0ANzIgLTIuNDE0MTQ1LC0wLjgxNTEyNSAtMC44NDQ5ODEsLTAuMjkwMTczIC0xLjcwMDM2OCwtMC41%0D%0ANDY1ODQgLTIuNTUyMzMyLC0wLjgxNTI5NCAtMC44ODU2MjQsLTAuMjcwNzU5IC0xLjc4OTI1LC0w%0D%0ALjQ4NDMzOSAtMi42ODkyOTQsLTAuNzA2MzY1IC0wLjkxMTU1OCwtMC4yMzMwMDMgLTEuODI2MDk0%0D%0ALC0wLjQ1MjAxMyAtMi43NDM2MDcsLTAuNjYxNzc0IC0wLjg2MDgyNCwtMC4xODc4OTIgLTEuNzIx%0D%0ANjYzLC0wLjM3ODQ0MSAtMi41OTg5NjgsLTAuNDg0MTMxIC0wLjc2NjU5OSwtMC4xNDY1ODQgLTEu%0D%0ANTMyODc5LC0wLjI5MTU1MiAtMi4zMDgzMjEsLTAuMzkwMTc4IC0wLjYzNTg4OSwtMC4xMDMwNjcg%0D%0ALTEuMjc3MDgyLC0wLjE4MzU0MSAtMS45MTkyNDQsLTAuMjQwNjE0IC0wLjUyNDI2MSwtMC4wNTQw%0D%0AMSAtMS4wNDc4ODYsLTAuMDY1NTMgLTEuNTc1NiwtMC4wNTA2MyAtMC41OTUxOTEsLTAuMDAyNyAt%0D%0AMS4xOTI1MjksMC4wMDczIC0xLjc4MzkxNiwwLjA3NjY3IC0wLjcyMzU5NiwwLjA5MzIyIC0xLjQz%0D%0ANDM5NiwwLjI1OTg5OSAtMi4xNDE2MTgsMC40MzAyNzQgLTAuNzE2MTUsMC4yMDE0NzEgLTEuNDMy%0D%0ANzQ2LDAuNDA4MTczIC0yLjEwNTcyMSwwLjcyMjQ3OSAtMC43MDAzOTMsMC4zMTk4NTkgLTEuMzcz%0D%0AODI2LDAuNjgyODY5IC0xLjk5NTI0LDEuMTMwNjUzIC0wLjU5NjMzLDAuNDM4MTE4IC0xLjE3MzQx%0D%0ANSwwLjkwMDc1NSAtMS43MjE3MTIsMS4zOTMwODUgLTAuNDQzMjI1LDAuNDE2ODkzIC0wLjkxNzAx%0D%0AOCwwLjgwNDU4MSAtMS4zMDQwODcsMS4yNzMxOTIgLTAuMzY5NDY0LDAuNDI4NzYgLTAuNjk5OTQy%0D%0ALDAuODgxOTcgLTEuMDI3NDczLDEuMzQwMDk5IDAsMCAtMC43NDAxOCwtNy44Njk2MTcgLTAuNzQw%0D%0AMTgsLTcuODY5NjE3IHoiCiAgICAgICBpbmtzY2FwZTpjb25uZWN0b3ItY3VydmF0dXJlPSIwIiAv%0D%0APgogIDwvZz4KPC9zdmc+Cg=="
