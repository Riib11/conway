{-# language GeneralizedNewtypeDeriving #-}
{-# language DeriveFunctor #-}
{-# language TypeFamilies #-}
module Conway
  ( mkGrid
  , basicRule
  , step
  , render
  , beacon
  , glider
  , blinker
  , at
  , Grid
  , Rule
  ) where

import qualified Data.Vector as V
import Control.Arrow ((***))
import Data.Functor.Compose (Compose(..))
import Data.Distributive (Distributive(..))
import Data.Functor.Rep (Representable(..), distributeRep)
import Control.Comonad (Comonad(..))
import Control.Monad (guard)

gridSize :: Int
gridSize = 20

type Rule = Grid Bool -> Bool
type Coord = (Int, Int)

newtype BoundedV a = BoundedV (V.Vector a)
  deriving (Show, Eq, Functor, Foldable)

instance Distributive BoundedV where
  distribute = distributeRep

instance Representable BoundedV where
  type Rep BoundedV = Int
  index (BoundedV v) i = v V.! mod i gridSize
  tabulate = BoundedV . V.generate gridSize

instance Distributive Grid where
  distribute = distributeRep

instance Representable Grid where
  type Rep Grid = Coord
  index (Grid _ g) = index g
  tabulate desc = Grid (0, 0) (tabulate desc)

data Grid a = Grid (Rep Grid) (Compose BoundedV BoundedV a)
  deriving (Functor)

instance Comonad Grid where
  extract (Grid i g) = index g i
  extend f (Grid i g) = tabulate (\j -> f (Grid j g))

basicRule :: Rule
basicRule (Grid i@(sx, sy) g) =
  (alive && numNeighbours `elem` [2, 3]) || (not alive && numNeighbours == 3)
  where
    alive = index g i
    numNeighbours = length (filter id neighbours)
    val True = 1
    val False = 0
    neighbours = do
      x <- [-1, 0, 1]
      y <- [-1, 0, 1]
      let coord = (x, y)
      guard $ coord /= (0, 0)
      return (index g (x + sx, y + sy))

step :: Rule -> Grid Bool -> Grid Bool
step = extend

render :: Grid Bool -> String
render (Grid _ (Compose g)) = foldMap ((++ "\n") . foldMap toS) g
  where
    toS True = "#"
    toS False = "."

mkGrid :: [Coord] -> Grid Bool
mkGrid = tabulate . flip elem

at :: [Coord] -> Coord -> [Coord]
at xs (x, y) = fmap ((+x) *** (+y)) xs

glider, blinker, beacon :: [Coord]
glider = [(1, 0), (2, 1), (0, 2), (1, 2), (2, 2)]
blinker = [(0, 0), (1, 0), (2, 0)]
beacon = [(0, 0), (1, 0), (0, 1), (3, 2), (2, 3), (3, 3)]
