-- | This module contains the data types
--   which represent the state of the game

{-# LANGUAGE OverloadedStrings #-}

module Model where

import Graphics.Gloss

import Data.Aeson

-- States of the game
data State = Menu | Running | GameOver | Paused

-- Vector2
data Vec2 = Vec2 (Float, Float)

-- All possible GameObjects
data GameObject =     Player {x :: Float, y :: Float, size :: Float, dir :: Float, speed :: Vec2, boosting :: Bool}
                | Asteroid {x :: Float, y :: Float, size :: Float, dir :: Float}
                | AlienShip {x :: Float, y :: Float, size :: Float, dir :: Float, timer :: Float}
                | Bullet {x :: Float, y :: Float, size :: Float, dir :: Float}
                | AlienBullet {x :: Float, y :: Float, size :: Float, dir :: Float}
                | Tekst {myID :: String, myIntID :: Int, x :: Float, y :: Float, string :: String, size :: Float, colour :: Color}
                
--TurnDirection
data TurnDir = Left | Right
-- Player Input for movement
data Input = Input {left :: Bool, right :: Bool, forward :: Bool, backward :: Bool}

-- GameState
data GameState = GameState {state :: State, objects :: [GameObject], elapsedTime :: Float, cntrls :: Input, lives :: Int, score :: Int, highscore :: Int, level :: Int}

data HighscoreEntry = HighscoreEntry {name :: String, value :: Int}
instance FromJSON HighscoreEntry where
    parseJSON = withObject "HighscoreEntry" $ \v -> HighscoreEntry
        <$> v .: "name"
        <*> v .: "value"
instance ToJSON HighscoreEntry where
    toJSON (HighscoreEntry name value) = object ["name" .= name, "value" .= value]
    toEncoding (HighscoreEntry name value) = pairs ("name" .= name <> "value" .= value)

-- All colors
playerColor = makeColor 1 0 0 1
boostColor = makeColor 1 0.8 0.8 1
asteroidColor = makeColor 1 1 0 1
alienColor = makeColor 0 0.5 0.5 1
bulletColor = makeColor 0 1 0 1
textColor = makeColor 1 1 1 1
selectTextColor = makeColor 0 0.5 1 1

-- pre-made GameObjects (currently used or used in the past for testing purposes)
player = Player {x = 0, y = 0, size = 30, dir = 0, speed = Vec2(0,0), boosting = False}
player2 = Player {x = 0, y = 100, size = 30, dir = 0, speed = Vec2(0,0), boosting = False}
asteroid = Asteroid {x = -40, y = -20, size = 80, dir = 0}
alien = AlienShip {x = -200, y = -200, size = 30, dir = 0, timer = 0}

-- pre-made Text GameObjects
livesText = Tekst {myID = "Lives", myIntID = 0, x = 230, y = 175, string = "", size = 0.3, colour = textColor}
scoreText = Tekst {myID = "Score", myIntID = 0, x = 0, y = 175, string = "", size = 0.3, colour = textColor}
highscoreText = Tekst {myID = "Highscore", myIntID = 0, x = 0, y = 125, string = "", size = 0.3, colour = textColor}
pauseText = Tekst {myID = "pause", myIntID = 0, x = 200, y = 225, string = "", size = 0.15, colour = textColor}

-- menuState (= 1 or multiple Text objects)
menuText = Tekst {myID = "menu", myIntID = 0, x = -300, y = 100, string = "Asteroids! Choose a level", size = 0.35, colour = textColor}
lvl1 = Tekst {myID = "menu", myIntID = 1, x = -300, y = 50, string = "Level 1: Only Asteroids", size = 0.2, colour = textColor}
lvl2 = Tekst {myID = "menu", myIntID = 2, x = -300, y = 0, string = "Level 2: Asteroids and Alien ships", size = 0.2, colour = textColor}
lvl3 = Tekst {myID = "menu", myIntID = 3, x = -300, y = -50, string = "Level 3: Only Alien ships", size = 0.2, colour = textColor}
infoFirstTime = Tekst {myID = "menu", myIntID = -1, x = -300, y = -90, string = "use W and S to scroll. Press Enter to choose mode", size = 0.15, colour = textColor}
menuState :: [GameObject]
menuState = [menuText, lvl1, lvl2, lvl3]

-- pausedState (= 1 or multiple Text objects)
pausedText = Tekst {myID = "", myIntID = 0, x = -300, y = 0, string = "Paused, press P to continue", size = 0.3, colour = textColor}
pausedState :: [GameObject]
pausedState = [pausedText]

-- gameverState (= 1 or multiple Text objects)
gameoverText = Tekst {myID = "", myIntID = 0, x = -250, y = 0, string = "Game Over! press Enter to play again", size = 0.2, colour = textColor}
goToMenuText = Tekst {myID = "", myIntID = 0, x = -250, y = -50, string = "Press B to pick a different mode", size = 0.2, colour = textColor}
gameoverState :: [GameObject]
gameoverState = [gameoverText, goToMenuText]

-- initialState
initialState :: GameState
initialState = GameState {state = Menu, objects = [player, scoreText, pauseText, livesText, menuText, lvl1, lvl2, lvl3, infoFirstTime], elapsedTime = 0, cntrls = Input{left = False, right = False, forward = False, backward = False}, lives = 3, score = 0, level = 1}
