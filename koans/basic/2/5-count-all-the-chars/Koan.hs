{- | Count the all the chars!

If we can count words, we surely can count characters as well.
But how do we output them _both_?

'ClSF's have an instance for the 'Arrow' type class.
This means that they can be composed sequentially (as you did already with '>>>'),
but also in parallel.
Let's look at one combinator that allows this:

@
(&&&) :: Monad m => ClSF m cl a b -> ClSF m cl a c -> ClSF m cl a (b, c)
@

If two signal functions are on the same monad, the same clock, and receive the same input,
we can combine them in parallel and execute both after each other.
Both outputs are combined in a tuple.
-}
module Koan where

-- text
import Data.Text (Text)
import Data.Text qualified as Text (length, words)

-- rhine
import FRP.Rhine hiding (currentInput)

-- | A line of user input.
userInput :: ClSF IO StdinClock () Text
userInput = tagS

-- | Output the number of words of the line that was just entered.
wordCount :: ClSF IO StdinClock () Int
wordCount = userInput >-> arr (Text.words >>> length)

{- | Output the number of characters of the line that was just entered.

The newline character is not part of 'userInput',
therefore +1 is added for it.
-}
charCount :: ClSF IO StdinClock () Int
-- Yes, you can use >>> to compose ordinary functions as well!
charCount = userInput >-> arr (Text.length >>> (+ 1))

-- | Compute the sum of all input numbers so far, including the current one.
sumClSF :: (Monad m, Num a) => ClSF m cl a a
sumClSF = feedback 0 $ arr aggregator
  where
    aggregator :: (Num a) => (a, a) -> (a, a)
    aggregator (currentInput, currentSum) =
      let
        nextSum = currentInput + currentSum
       in
        (nextSum, nextSum)

-- | The number of words of input so far.
totalWordCount :: ClSF IO StdinClock () Int
totalWordCount = wordCount >-> sumClSF

-- | The number of characters of input so far.
totalCharCount :: ClSF IO StdinClock () Int
-- Reuse your sum utility!
totalCharCount = charCount >-> sumClSF

-- | The number of total words and characters so far.
totalWordAndCharCount :: ClSF IO StdinClock () (Int, Int)
totalWordAndCharCount = totalWordCount &&& totalCharCount

-- | Print the number of total words and characters so far.
printAllCounts :: ClSF IO StdinClock () ()
printAllCounts = totalWordAndCharCount >-> arrMCl (\(words_, chars) -> print words_ >> print chars)

main :: IO ()
main = flow $ printAllCounts @@ StdinClock
