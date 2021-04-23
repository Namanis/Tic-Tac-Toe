module Task3Parse where
import Data.List as L 
import Data.Char as C
import Data.Ord (comparing)
import Task2Message


getInt :: String -> String -> (String, String)
getInt [] acc= (acc, [])
getInt all@(x:xs) acc = if isDigit x then getInt xs (acc ++ [x]) else (acc, all)

parseJLInt :: String -> Either String (JsonLikeValue, String)
parseJLInt ('i':xs) = case getInt xs [] of 
                            ([], _) -> Left "Integer not found"
                            (x, ('e':xs)) -> Right (JLInt (read(x)), xs)
                            (_, _) -> Left "Not an Integer"
parseJLInt _ =  Left "Not an Integer"

parseJLString :: [Char] -> Either [Char] (JsonLikeValue, [Char])
parseJLString (x:xs) = Right (JLString [x],xs) 
parseJLString _ = Left "Error not char parse" 

parseMap :: String -> Either String (JsonLikeValue, String)
parseMap ('4':':':'l':'a':'s':'t':xs) = Right(JLString "last", xs)
parseMap ('4':':':'p':'r':'e':'v':xs) = Right(JLString "prev", xs)
parseMap ('4':':':'d':'a':'t':'a':xs) = Right(JLString "Data", xs)
parseMap _ = Left "Bad last or prev input" 


parseArray :: [Char] -> Either [Char] (JsonLikeValue, [Char])
parseArray ('l':xs) = parseArray' xs (JLArray [])
parseArray _ = Left "Error in Array"

parseArray' ('e':xs) (JLArray acc) = Right (JLArray acc, xs)

parseArray' x (JLArray acc) = case parseWholeArray x of 
                                    Right (x,xs) -> parseArray' xs (JLArray(acc ++ [x]))
                                    Left k -> Left "Error parsing array"

parseArray' _ _ = Left "Unexpected Error in array"

parseWholeArray :: String -> Either String (JsonLikeValue, String)
parseWholeArray all@('l':_) = case parseArray all of
                               Left k -> Left k
                               Right result -> Right result
parseWholeArray all@('i':_) = case parseJLInt all of 
                               Left k -> Left k
                               Right result -> Right result
parseWholeArray ('1':':':xs) = case parseJLString xs of
                               Left k -> Left k
                               Right result -> Right result
parseWholeArray all@('4':':':xs) = case parseMap all of
                               Left k -> Left k
                               Right result -> Right result
parseWholeArray _ = Left "Parse error. Unknown type usage"

parse :: Int                         -- ^ Size of the matrix (number of columns or rows)
      -> String                      -- ^ Encoded message
      -> Either String JsonLikeValue -- ^ Parsed data structure or error message

parse _ x = case parseWholeArray x of
                    Right(x, _) -> Right x
                    Left k -> Left k

parseCheck :: Bool
parseCheck = case (parse size message, expectedParse) of
  (Right m, Right e) -> m == e
  (Left _, Left _) -> True
  _ -> False
{-========================================================================================================-}
-----------------------------------------------------------------------------------------------------------



extractValue :: JsonLikeValue -> (Int, Int, Char)
extractValue (JLArray[JLArray[JLString "Data", JLArray[x, y, v]]]) =
    case (x, y, v) of
        (JLInt x, JLInt y, JLString v) ->(x, y, head v)


getMoveOrder :: JsonLikeValue -> [(Int, Int, Char)]
getMoveOrder value = extract value
    where extract value =
            case value of 
                JLArray[JLString "prev", c0, JLString "last", c1] -> (extractValue c1) : (extract c0)
                JLArray[JLString "last", c0, JLString "prev", c1] -> (extractValue c0) : (extract c1)
                JLArray[JLString "last", c1] -> (extractValue c1) : []

{-
sortByYX :: [(Int, Int, Char)] -> [(Int, Int, Char)]
sortByYX array = sortBy (comparing (\(x,y,_) -> (x,y))) $ array
-}

validateOrder :: [(Int, Int, Char)] -> Either InvalidState Bool
validateOrder [] = Right True
validateOrder [_] = Right True
validateOrder array =
    let 
        x = head array
        x1 = head (tail array)
        c1 = getThirdOfTuple x
        c2 = getThirdOfTuple x1
    in 
        if c1 == c2 then Left $ Order else validateOrder (tail array)

checkForDuplicates :: [(Int, Int, Char)] -> Either InvalidState Bool
checkForDuplicates [] = Right False
checkForDuplicates [_] = Right False
checkForDuplicates array =
    let 
        x = head array
        x1 = head(tail array)
        (i1, i2) = getIntsOfTuple x
        (i3, i4) = getIntsOfTuple x1
    in 
        if (i1, i2) == (i3, i4) then Left $ Duplicates else checkForDuplicates (tail array) 


getIntsOfTuple :: (Int, Int, Char) -> (Int, Int)
getIntsOfTuple (i1, i2, _) = (i1, i2)

getThirdOfTuple :: (Int, Int, Char) -> Char
getThirdOfTuple (_, _, c) = c 



convert :: Int -> JsonLikeValue -> Either InvalidState To
convert _ jValue =
    case getMoveOrder jValue of
        tupArr -> case validateOrder tupArr of
                        Left k -> Left k
                        Right True -> case checkForDuplicates(tupArr) of
                                             Left k -> Left k
                                             Right False -> Right $ tupArr