-- | This module defines how the state changes
--   in response to time and user input

{-# LANGUAGE OverloadedStrings #-}

module Controller where

import Model

import Graphics.Gloss
import Graphics.Gloss.Interface.IO.Game
import System.Random
import Data.Aeson
import qualified Data.ByteString.Lazy as B

-- Handle user input depending on gamestate
input :: Event -> GameState -> IO GameState
input event gstate = case state gstate of
                                Menu -> menuInput event gstate
                                Running -> runningInput event gstate
                                GameOver -> gameoverInput event gstate
                                Paused -> pausedInput event gstate

-- Handle user input when on Menu Screen
menuInput :: Event -> GameState -> IO GameState
menuInput event gstate = case event of
                                (EventKey (Char 'w') Down _ _) -> if(level gstate > 1) then return gstate {level = level gstate - 1} else return gstate
                                (EventKey (Char 's') Down _ _) -> if(level gstate < 3) then return gstate {level = level gstate + 1} else return gstate
                                (EventKey (SpecialKey keyEnter) Down _ _) -> return gstate {state = Running, lives = 3, score = 0, cntrls = Input{left = False, right = False, forward = False, backward = False}}
                                (EventKey (SpecialKey keySpace) Down _ _) -> return gstate {state = Running, lives = 3, score = 0, cntrls = Input{left = False, right = False, forward = False, backward = False}}
                                _ -> return gstate

-- Handle user input when game is paused                                
pausedInput :: Event -> GameState -> IO GameState
pausedInput event gstate = case event of
                                (EventKey (Char 'p') Down _ _) -> return gstate {state = Running}
                                _ -> return gstate

-- Handle user input when game over                                
gameoverInput :: Event -> GameState -> IO GameState
gameoverInput event gstate = case event of
                                (EventKey (Char 'b') Down _ _) -> return gstate{state = Menu}
                                (EventKey (SpecialKey KeyEnter) Down _ _) -> return gstate {state = Running, lives = 3, score = 0, cntrls = Input{left = False, right = False, forward = False, backward = False}}
                                _ -> return gstate

-- Handle user input when playing the game (/when game is running)
runningInput :: Event -> GameState -> IO GameState
runningInput event gstate = case event of
                        (EventKey (Char 'w') Down _ _) -> do
                                                                return gstate {cntrls = (cntrls gstate) {forward = True}}
                        (EventKey (Char 's') Down _ _) -> do
                                                                return gstate {cntrls = (cntrls gstate) {backward = True}}
                        (EventKey (Char 'a') Down _ _) -> do
                                                                return gstate {cntrls = (cntrls gstate) {left = True}}
                        (EventKey (Char 'd') Down _ _) -> do
                                                                return gstate {cntrls = (cntrls gstate) {right = True}}
                        (EventKey (SpecialKey KeySpace) Down _ _) -> do
                                                                return gstate {objects = objects gstate ++ [newBullet (x (objects gstate!!0)) (y (objects gstate!!0)) (dir (objects gstate!!0))]}
                        (EventKey (Char 'w') Up _ _) -> do
                                                                return gstate {cntrls = (cntrls gstate) {forward = False}}
                        (EventKey (Char 's') Up _ _) -> do
                                                                return gstate {cntrls = (cntrls gstate) {backward = False}}
                        (EventKey (Char 'a') Up _ _) -> do
                                                                return gstate {cntrls = (cntrls gstate) {left = False}}
                        (EventKey (Char 'd') Up _ _) -> do
                                                                return gstate {cntrls = (cntrls gstate) {right = False}}
                        (EventKey (Char 'p') Down _ _) -> do
                                                                return gstate {state = Paused}
                        _ -> return gstate

-- Spawning a new bullet
newBullet :: Float -> Float -> Float -> GameObject
newBullet x y dir = Bullet {x=x, y=y, size=10, dir = dir}

-- Move the Player
movePlayer :: GameObject -> Input -> GameObject
movePlayer obj inpt = do
                        let o1 = if left inpt then Controller.rotate obj (-1) else obj
                        let o2 = if right inpt then Controller.rotate o1 1 else o1
                        let direction = dir o2
                        let Vec2(vx,vy) = speed o2
                        let inc = vx / 60
                        let dx = if forward inpt && lngt (vx,vy) < 2 then vx + 0.1 * sin(direction * pi/180) - inc else vx - inc
                        let inc = vy / 60
                        let dy = if forward inpt && lngt (vx,vy) < 2 then vy + 0.1 * cos(direction * pi/180) - inc else vy - inc
                        let boost = if forward inpt then True else False
                        o2{x = x o2 + dx, y = y o2 + dy, speed = Vec2(dx,dy), boosting = boost}
                                where lngt (vx,vy) = sqrt(vx*vx + vy*vy)

-- Rotate an GameObject                                
rotate :: GameObject -> Float -> GameObject
rotate obj n = obj {dir = (dir obj) + n}

-- Move an GameObject in a certain direction
moveDir :: GameObject -> Float -> Float -> GameObject
moveDir obj dir n = obj {y = (y obj) + n * cos(dir * pi/180), x = (x obj) + n * sin(dir * pi/180)}

-- Get a random IO Float
randomNumber :: Float -> Float -> IO Float
randomNumber low high = randomRIO(low,high)

-- Choose step function dependign on gamestate
step :: Float -> GameState -> IO GameState
step secs gstate = case state gstate of
                      Menu -> menuStep secs gstate
                      Running -> runningStep secs gstate
                      GameOver -> gameoverStep secs gstate
                      Paused -> pausedStep secs gstate

-- Step function when on menu
menuStep :: Float -> GameState -> IO GameState
menuStep secs gstate = do 
                                let texts = [changeTextMenu (changeTextColor x gstate) | x <- getTexts (objects gstate)]
                                return gstate{objects = (getAllNoTexts (objects gstate)) ++ texts}

-- Step function when game is running
runningStep :: Float -> GameState -> IO GameState
runningStep secs gstate = do
                            let objs = objects gstate
                            let playerDied = collideList (getAsteroids objs ++ getAliens objs) (objs!!0)
                            let player = if (playerDied)
                                                        then Player {x = 0, y = 0, size = 30, dir = 0, speed = Vec2(0,0), boosting = False}
                                                        else movePlayer (objs!!0) (cntrls gstate)
                            --let player2 = movePlayer (objs!!1) (cntrls gstate) --for local mulitplayer (WIP)
                            let newAsteroids = if(playerDied)
                                                        then []
                                                        else concat [splitAsteroid (moveDir obj (dir obj) 0.7) (getBullets objs) | obj <- getAsteroids objs, abs (x obj) <= 668, abs (y obj) <= 412]
                            let newBullets = [moveDir obj (dir obj) 5 | obj <- getBullets objs, abs (x obj) <= 668, abs (y obj) <= 412, collideList (getAsteroids objs ++ getAliens objs) obj == False]
                            --let newAlienBullets = [moveDir obj (dir obj) 1 | obj <- getAlienBullets objs, abs (x obj) <= 668, abs (y obj) <= 412] --AlienShip shooting (WIP)
                            let newAliens = if (playerDied) 
                                                        then []
                                                        else concat [alienShootCheck (moveDir obj (dir (newAlienDirection obj player)) 0.4) secs | obj <- getAliens objs, abs (x obj) <= 668, abs (y obj) <= 412, collideList (getBullets objs) obj == False]
                            let newTexts = [changeText x gstate | x <- getTexts objs]
                            let newlives = if(playerDied)
                                                        then (lives gstate-1)
                                                        else lives gstate
                            let newState = if(lives gstate <= 0)
                                                        then GameOver
                                                        else state gstate
                            let newScore = if(collideList2 (getAsteroids objs ++ getAliens objs) (getBullets objs))
                                                        then score gstate + 10
                                                        else score gstate
                            let newhighscore = if(newlives <= 0 && highscore gstate < newScore)
                                                        then newScore
                                                        else highscore gstate
                            if(newlives <= 0 && highscore gstate < newScore)    then B.writeFile "src/highscores.json" (encode (HighscoreEntry {name = "Player", value = newScore}))
                                                                                else return()
                            case elapsedTime gstate + secs >= 0.7 of
                              True -> do
                                    newast <- newAsteroid
                                    newalien <- newAlien
                                    random <- randomNumber 0 3
                                    let newobject = if(level gstate == 2)
                                                        then if(round random == 0)      then newalien
                                                                                        else newast
                                                        else if (level gstate == 1) then newast
                                                        else newalien
                                    return $ (gstate {elapsedTime = 0, objects = player : newobject : newAsteroids ++ newBullets {-++ newAlienBullets-} ++ newAliens ++ newTexts, lives = newlives, state = newState, score = newScore, highscore = newhighscore})
                              _ -> do
                                    return $ (gstate {elapsedTime = elapsedTime gstate + secs, objects = player : newAsteroids ++ newBullets {-++ newAlienBullets-} ++ newAliens ++ newTexts, lives = newlives, state = newState, score = newScore, highscore = newhighscore})

-- Step function when game over                                    
gameoverStep :: Float -> GameState -> IO GameState
gameoverStep secs gstate = return gstate

-- Step function when game is paused
pausedStep :: Float -> GameState -> IO GameState
pausedStep secs gstate = return gstate

alienShootCheck :: GameObject -> Float -> [GameObject]
alienShootCheck alien secs      | timer alien > 2 = [alien] --[alien{timer = 0}, AlienBullet {x = x alien, y = y alien, size = 10, dir = dir alien}]
                                | otherwise = [alien{timer = timer alien + secs}]

-- Return a new random Asteroid
newAsteroid :: IO GameObject
newAsteroid = do
                let posoffset = 0
                randPos <- randomNumber 0 3
                randSize <- randomNumber 20 50
                randDir <- randomNumber (-45) 45
                case round randPos of
                      0 -> do randX <- randomNumber (-384+posoffset) (384-posoffset)
                              return Asteroid {x = randX, y = (-256-30), size = randSize, dir = randDir}
                      1 -> do randY <- randomNumber (-256+posoffset) (256-posoffset)
                              return Asteroid {x = (-384-30), y = randY, size = randSize, dir = randDir + (randPos*90)}
                      2 -> do randX <- randomNumber (-384+posoffset) (384-posoffset)
                              return Asteroid {x = randX, y = (256+30), size = randSize, dir = randDir + (randPos*90)}
                      3 -> do randY <- randomNumber (-256+posoffset) (256-posoffset)
                              return Asteroid {x = (384+30), y = randY, size = randSize, dir = randDir + (randPos*90)}

newAlien :: IO GameObject
newAlien = do
                let posoffset = 0
                randPos <- randomNumber 0 3
                case round randPos of
                        0 -> do randX <- randomNumber (-384+posoffset) (384-posoffset)
                                return AlienShip {x = randX, y = (-256-30), size = 30, dir = 0, timer = 0}
                        1 -> do randY <- randomNumber (-256+posoffset) (256-posoffset)
                                return AlienShip {x = (-384-30), y = randY, size = 30, dir = 0, timer = 0}
                        2 -> do randX <- randomNumber (-384+posoffset) (384-posoffset)
                                return AlienShip {x = randX, y = (256+30), size = 30, dir = 0, timer = 0}
                        3 -> do randY <- randomNumber (-256+posoffset) (256-posoffset)
                                return AlienShip {x = (384+30), y = randY, size = 30, dir = 0, timer = 0}

-- Check for collision between 2 objects
collide :: GameObject -> GameObject -> Bool
{-collide obj1@Asteroid{} obj2@Player{}   | (x obj2 - x obj1)^2 + (y obj1 - y obj2)^2 <= (size obj1 + size obj2)^2 = True
                                        | otherwise = False
collide obj1@Asteroid{} obj2@Bullet{}   | (x obj2 - x obj1)^2 + (y obj1 - y obj2)^2 <= (size obj1 + size obj2)^2 = True
                                        | otherwise = False
collide obj1@Bullet{} obj2@Asteroid{}   | (x obj2 - x obj1)^2 + (y obj1 - y obj2)^2 <= (size obj1 + size obj2)^2 = True
                                        | otherwise = False
collide obj1@AlienShip{} obj2@Player{}  | (x obj2 - x obj1)^2 + (y obj1 - y obj2)^2 <= (size obj1 + size obj2)^2 = True
                                        | otherwise = False
collide _ _ = False-}
collide obj1 obj2       | (x obj2 - x obj1)^2 + (y obj1 - y obj2)^2 <= (size obj1 + size obj2)^2 = True
                        | otherwise = False

-- Check Collision between a list of objects and a single object
collideList :: [GameObject] -> GameObject -> Bool
collideList list obj = elem True [collide x obj | x <- list]

-- Check collision between 2 lists of objects
collideList2 :: [GameObject] -> [GameObject] -> Bool
collideList2 list list2 = elem True [collideList list x | x <- list2]

-- Split an Asteroid into 2 smaller asteroids
splitAsteroid :: GameObject -> [GameObject] -> [GameObject]
splitAsteroid obj list  | collideList list obj && size obj > 30 = [obj {dir = dir obj + 45, size = size obj-15}, obj {dir = dir obj - 45, size = size obj-15}]
                        | collideList list obj && size obj <= 30 = []
                        | otherwise = [obj]

-- Intellegent alien movement (movement direction based on position of the player and its own)
newAlienDirection :: GameObject -> GameObject -> GameObject
newAlienDirection alien player  | x alien-x player < 0 = alien{dir = 180+270-atan((y alien-y player)/(x alien-x player))* 180/pi}
                                | otherwise = alien{dir = 270-atan((y player-y alien)/(x player-x alien))* 180/pi}

-- Update all the text objects
changeText :: GameObject -> GameState -> GameObject
changeText obj@Tekst{myID=id, x=_, y=_, string=_} gstate = case id of
                                                        "Lives" -> obj{string = show (lives gstate) ++ " lives"}
                                                        "Score" -> obj{string = show (score gstate)}
                                                        "menu" ->  obj{string = ""}
                                                        "pause" -> obj{string = "Press p to Pause"}
                                                        "" -> obj
                                                        _ -> obj{string = "ERROR: ID not found"}

changeTextMenu :: GameObject -> GameObject
changeTextMenu obj@Tekst{myID=id} = case id of
                                                "Lives" -> obj{string = ""}
                                                "Score" -> obj{string = ""}
                                                "menu" ->       if(myIntID obj == 0) then obj{string = "Asteroids! Choose a level"}
                                                                else if(myIntID obj == 1) then obj{string = "Level 1: Only Asteroids"}
                                                                else if(myIntID obj == 2) then obj{string = "Level 2: Asteroids and Alien ships"}
                                                                else if(myIntID obj == 3) then obj{string = "Level 3: Only Alien ships"}
                                                                else obj
                                                "pause" -> obj{string = ""}
                                                "" -> obj
                                                _ -> obj{string = "ERROR: ID not found"}

changeTextColor :: GameObject -> GameState -> GameObject
changeTextColor txt gstate      | myIntID txt == level gstate = txt{colour=selectTextColor}
                                | otherwise = txt{colour = textColor}

-- Update the score and highscore on the game over screen
getScore :: GameObject -> GameState -> GameObject
getScore obj@Tekst{myID=id, x=_, y=_, string=_} gstate = case id of
                                                        "Highscore" -> obj{string = "Highscore: " ++ show (highscore gstate)}
                                                        "Score" -> obj{string = "Score: " ++ show (score gstate)}
                                                        "" -> obj
                                                        _ -> obj{string = "ERROR: ID not found"}

-- \/\/\/ Get GameObjects from onscreen list \/\/\/
getAsteroids :: [GameObject] -> [GameObject]
getAsteroids list = [x | x <- list, isAsteroid x]

isAsteroid :: GameObject -> Bool
isAsteroid Asteroid{} = True
isAsteroid _ = False

getBullets :: [GameObject] -> [GameObject]
getBullets list = [x | x <- list, isBullet x]

isBullet :: GameObject -> Bool
isBullet Bullet{} = True
isBullet _ = False

getAlienBullets :: [GameObject] -> [GameObject]
getAlienBullets list = [x | x <- list, isAlienBullet x]

isAlienBullet :: GameObject -> Bool
isAlienBullet AlienBullet{} = True
isAlienBullet _ = False

getAliens :: [GameObject] -> [GameObject]
getAliens list = [x | x <- list, isAlien x]

isAlien :: GameObject -> Bool
isAlien AlienShip{} = True
isAlien _ = False

getPlayers :: [GameObject] -> [GameObject]
getPlayers list = [x | x <- list, isPlayer x]

isPlayer :: GameObject -> Bool
isPlayer Player{} = True
isPlayer _ = False

getTexts :: [GameObject] -> [GameObject]
getTexts list = [x | x <- list, isText x]

isText :: GameObject -> Bool
isText Tekst{} = True
isText _ = False

getAllNoTexts :: [GameObject] -> [GameObject]
getAllNoTexts list = [x | x <- list, isText x == False]