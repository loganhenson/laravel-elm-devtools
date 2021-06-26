module Colors exposing (..)


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
