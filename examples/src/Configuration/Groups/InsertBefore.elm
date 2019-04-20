module Configuration.Groups.InsertBefore exposing (Model, Msg, init, initialModel, main, subscriptions, update, view)

import Browser
import DnDList.Groups
import Html
import Html.Attributes



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- DATA


type alias Meta =
    { value : String
    , color : String
    }


type alias Item =
    { group : Int
    , meta : Meta
    }


gatheredByGroup : List Item
gatheredByGroup =
    [ { group = 0, meta = Meta "2" red }
    , { group = 0, meta = Meta "B" blue }
    , { group = 0, meta = Meta "A" blue }
    , { group = 0, meta = Meta "III" green }
    , { group = 0, meta = Meta "" transparent }
    , { group = 1, meta = Meta "C" blue }
    , { group = 1, meta = Meta "1" red }
    , { group = 1, meta = Meta "I" green }
    , { group = 1, meta = Meta "3" red }
    , { group = 1, meta = Meta "" transparent }
    , { group = 2, meta = Meta "II" green }
    , { group = 2, meta = Meta "" transparent }
    ]



-- SYSTEM


config : DnDList.Groups.Config Item
config =
    { movement = DnDList.Groups.Free
    , trigger = DnDList.Groups.OnDrag
    , operation = DnDList.Groups.Swap
    , beforeUpdate = \_ _ list -> list
    , groups =
        { comparator = compareByGroup
        , operation = DnDList.Groups.InsertBefore
        , beforeUpdate = updateOnGroupChange
        }
    }


system : DnDList.Groups.System Item Msg
system =
    DnDList.Groups.create config MyMsg


updateOnGroupChange : Int -> Int -> List Item -> List Item
updateOnGroupChange dragIndex dropIndex list =
    let
        dropItem : List Item
        dropItem =
            list |> List.drop dropIndex |> List.take 1
    in
    list
        |> List.indexedMap
            (\index item ->
                if index == dragIndex then
                    List.map2
                        (\element dropElement ->
                            { element | group = dropElement.group }
                        )
                        [ item ]
                        dropItem

                else
                    [ item ]
            )
        |> List.concat


compareByGroup : Item -> Item -> Bool
compareByGroup dragElement dropElement =
    dragElement.group == dropElement.group



-- MODEL


type alias Model =
    { draggable : DnDList.Groups.Draggable
    , items : List Item
    }


initialModel : Model
initialModel =
    { draggable = system.draggable
    , items = gatheredByGroup
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    system.subscriptions model.draggable



-- UPDATE


type Msg
    = MyMsg DnDList.Groups.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        MyMsg msg ->
            let
                ( draggable, items ) =
                    system.update msg model.draggable model.items
            in
            ( { model
                | draggable = draggable
                , items = items
              }
            , system.commands model.draggable
            )



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.section sectionStyles
        [ model.items
            |> List.filter (\{ group } -> group == 0)
            |> List.indexedMap (itemView model 0)
            |> Html.div containerStyles
        , model.items
            |> List.filter (\{ group } -> group == 1)
            |> List.indexedMap (itemView model (calculateOffset 0 1 model.items))
            |> Html.div containerStyles
        , model.items
            |> List.filter (\{ group } -> group == 2)
            |> List.indexedMap (itemView model (calculateOffset 0 2 model.items))
            |> Html.div containerStyles
        , draggedItemView model
        ]


itemView : Model -> Int -> Int -> Item -> Html.Html Msg
itemView model offset localIndex { group, meta } =
    let
        globalIndex : Int
        globalIndex =
            localIndex + offset

        itemId : String
        itemId =
            "end-" ++ String.fromInt globalIndex
    in
    case ( system.info model.draggable, maybeDraggedItem model ) of
        ( Just { dragIndex }, Just dragItem ) ->
            if meta.value == "" && group /= dragItem.group then
                Html.div
                    (Html.Attributes.id itemId :: auxiliaryItemStyles ++ system.dropEvents globalIndex itemId)
                    []

            else if meta.value == "" && group == dragItem.group then
                Html.div
                    (Html.Attributes.id itemId :: auxiliaryItemStyles)
                    []

            else if globalIndex /= dragIndex then
                Html.div
                    (Html.Attributes.id itemId :: itemStyles meta.color ++ system.dropEvents globalIndex itemId)
                    [ Html.text meta.value ]

            else
                Html.div
                    (Html.Attributes.id itemId :: itemStyles gray)
                    []

        _ ->
            if meta.value == "" then
                Html.div
                    (Html.Attributes.id itemId :: auxiliaryItemStyles)
                    []

            else
                Html.div
                    (Html.Attributes.id itemId :: itemStyles meta.color ++ draggableItemStyles ++ system.dragEvents globalIndex itemId)
                    [ Html.text meta.value ]


draggedItemView : Model -> Html.Html Msg
draggedItemView model =
    case maybeDraggedItem model of
        Just { meta } ->
            Html.div
                (itemStyles meta.color ++ draggableItemStyles ++ system.draggedStyles model.draggable)
                [ Html.text meta.value ]

        _ ->
            Html.text ""



-- HELPERS


calculateOffset : Int -> Int -> List Item -> Int
calculateOffset index group list =
    case list of
        [] ->
            0

        x :: xs ->
            if x.group == group then
                index

            else
                calculateOffset (index + 1) group xs


maybeDraggedItem : Model -> Maybe Item
maybeDraggedItem { draggable, items } =
    system.info draggable
        |> Maybe.andThen (\{ dragIndex } -> items |> List.drop dragIndex |> List.head)



-- COLORS


green : String
green =
    "#858c45"


red : String
red =
    "#8c4585"


blue : String
blue =
    "#45858c"


gray : String
gray =
    "dimgray"


transparent : String
transparent =
    "transparent"



-- STYLES


sectionStyles : List (Html.Attribute msg)
sectionStyles =
    [ Html.Attributes.style "display" "flex"
    , Html.Attributes.style "flex-direction" "column"
    , Html.Attributes.style "width" "700px"
    ]


containerStyles : List (Html.Attribute msg)
containerStyles =
    [ Html.Attributes.style "display" "flex"
    , Html.Attributes.style "justify-content" "end"
    , Html.Attributes.style "padding-bottom" "3em"
    ]


itemStyles : String -> List (Html.Attribute msg)
itemStyles color =
    [ Html.Attributes.style "width" "50px"
    , Html.Attributes.style "height" "50px"
    , Html.Attributes.style "border-radius" "8px"
    , Html.Attributes.style "color" "white"
    , Html.Attributes.style "cursor" "pointer"
    , Html.Attributes.style "margin-right" "2em"
    , Html.Attributes.style "display" "flex"
    , Html.Attributes.style "align-items" "center"
    , Html.Attributes.style "justify-content" "center"
    , Html.Attributes.style "background" color
    ]


draggableItemStyles : List (Html.Attribute msg)
draggableItemStyles =
    [ Html.Attributes.style "cursor" "pointer" ]


auxiliaryItemStyles : List (Html.Attribute msg)
auxiliaryItemStyles =
    [ Html.Attributes.style "flex-grow" "1"
    , Html.Attributes.style "box-sizing" "border-box"
    , Html.Attributes.style "margin-right" "2em"
    , Html.Attributes.style "width" "auto"
    , Html.Attributes.style "height" "50px"
    , Html.Attributes.style "min-width" "50px"
    , Html.Attributes.style "border" "3px dashed dimgray"
    , Html.Attributes.style "background" "transparent"
    ]
