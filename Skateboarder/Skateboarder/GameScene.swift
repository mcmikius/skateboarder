//
//  GameScene.swift
//  Skateboarder
//
//  Created by Michail Bondarenko on 5/27/19.
//  Copyright © 2019 Michail Bondarenko. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Enum для положения секции по y
    // Секции на земле низкие, а секции на верхней платформе высокие
    enum BrickLevel: CGFloat {
        case low = 0.0
        case high = 100.0
    }
    // Массив, содержащий все текущие секции тротуара
    var bricks = [SKSpriteNode]()
    
    // Массив,содержащий все активные алмазы
    var gems = [SKSpriteNode]()
    
    // Размер секций на тротуаре
    var brickSize = CGSize.zero
    
    // Текущий уровень определяет положение по оси y для новых секций
    var brickLevel = BrickLevel.low
    
    // Настройка скорости движения направо для игры
    // Это значение может увеличиваться по мере продвижения пользователя в игре
    var scrollSpeed: CGFloat = 5.0
    let startingScrollSpeed: CGFloat = 5.0
    // Константа для гравитации (того, как быстро объекты падают на Землю)
    let gravitySpeed: CGFloat = 1.5
    // Время последнего вызова для метода обновления
    var lastUpdateTime: TimeInterval?
    // Здесь мы создаем героя игры - скейтбордистку
    let skater = Skater(imageNamed: "skater")
    
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        physicsWorld.contactDelegate = self
        
        anchorPoint = CGPoint.zero
        
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
        // Создаем скейтбордистку и добавляем ее к сцене
        skater.setupPhysicsBody()
        addChild(skater)
        // Добавляем распознаватель нажатия, чтобы знать, когда пользователь нажимает на экран
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        startGame()
    }
    
    func resetSkater() {
        
        // Задаем начальное положение скейтбордистки, zPosition, а также minimumY
        let skaterX = frame.midX / 2.0
        let skaterY = skater.frame.height / 2.0 + 64.0
        skater.position = CGPoint(x: skaterX, y: skaterY)
        skater.zPosition = 10
        skater.minimumY = skaterY
        skater.zRotation = 0.0
        skater.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        skater.physicsBody?.angularVelocity = 0.0
    }
    
    func startGame() {
        // Возвращение к начальным условиям при запуске новой игры
        resetSkater()
        scrollSpeed = startingScrollSpeed
        brickLevel = .low
        lastUpdateTime = nil
        for brick in bricks {
            brick.removeFromParent()
        }
        bricks.removeAll(keepingCapacity: true)
        for gem in gems {
            removeGem(gem)
        }
    }
    
    func gameOver() {
        startGame()
        
    }
    
    func spawnBrick(atPosition position: CGPoint) -> SKSpriteNode {
        
        // Создаем спрайт секции и добавляем его к сцене
        let brick = SKSpriteNode(imageNamed: "sidewalk")
        brick.position = position
        brick.zPosition = 8
        addChild(brick)
        
        // Обновляем свойство brickSize реальным значением размера секции
        brickSize = brick.size
        
        // Добавляем новую секцию к массиву
        bricks.append(brick)
        // Настройка физического тела секции
        let center = brick.centerRect.origin
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: center)
        brick.physicsBody?.affectedByGravity = false
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = 0
        // Возвращаем новую секцию вызывающему коду
        return brick
    }
    
    func spawnGem(atPosition position: CGPoint) {
        // Создаем спрайт для алмаза и добавляем его к сцене
        let gem = SKSpriteNode(imageNamed: "gem")
        gem.position = position
        gem.zPosition = 9
        addChild(gem)
        gem.physicsBody = SKPhysicsBody(rectangleOf: gem.size, center: gem.centerRect.origin)
        gem.physicsBody?.categoryBitMask = PhysicsCategory.gem
        gem.physicsBody?.affectedByGravity = false
        // Добавляем новый алмаз к массиву
        gems.append(gem)
    }
    
    func removeGem(_ gem: SKSpriteNode) {
        gem.removeFromParent()
        if let gemIndex = gems.firstIndex(of: gem) {
            gems.remove(at: gemIndex)
        }
    }
    
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
        // Отслеживаем самое большое значение по оси x для всех существующих секций
        var farthestRightBrickX: CGFloat = 0.0
        
        for brick in bricks {
            
            let newX = brick.position.x - currentScrollAmount
            
            // Если секция сместилась слишком далеко влево (за пределы экрана), удалите ее
            if newX < -brickSize.width {
                
                brick.removeFromParent()
                
                if let brickIndex = bricks.firstIndex(of: brick) {
                    bricks.remove(at: brickIndex)
                }
                
            } else {
                
                // Для секции, оставшейся на экране, обновляем положение
                brick.position = CGPoint(x: newX, y: brick.position.y)
                
                //Обновляем значение для крайней правой секции
                if brick.position.x > farthestRightBrickX {
                    farthestRightBrickX = brick.position.x
                }
            }
        }
        
        // Цикл while, обеспечивающий постоянное наполнение экрана секциями
        while farthestRightBrickX < frame.width {
            
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = (brickSize.height / 2.0) + brickLevel.rawValue
            
            // Время от времени мы оставляем разрывы, через которые герой должен перепрыгнуть
            let randomNumber = arc4random_uniform(99)
            
            if randomNumber < 5 {
                
                // 5-процентный шанс на то, что у нас
                // возникнет разрыв между секциями
                let gap = 20.0 * scrollSpeed
                brickX += gap
                // На каждом разрыве добавляем алмаз
                let randomGemYAmount = CGFloat(arc4random_uniform(150))
                let newGemY = brickY + skater.size.height + randomGemYAmount
                let newGemX = brickX - gap / 2.0
                spawnGem(atPosition: CGPoint(x: newGemX, y: newGemY))
            } else if randomNumber < 10 {
                // В игре имеется 5-процентный шанс на изменение уровня секции
                if brickLevel == .high {
                    brickLevel = .low
                } else if brickLevel == .low {
                    brickLevel = .high
                }
            }
            
            // Добавляем новую секцию и обновляем положение самой правой
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
        }
    }
    
    func updateGems(withScrollAmount currentScrollAmount: CGFloat) {
        for gem in gems {
            // Обновляем положение каждого алмаза
            let thisGemX = gem.position.x - currentScrollAmount
            gem.position = CGPoint(x: thisGemX, y: gem.position.y)
            // Удаляем любые алмазы, ушедшие с экрана
            if gem.position.x < 0.0 {
                removeGem(gem)
            }
        }
    }
    
    func updateSkater() {
        // Определяем, находится ли скейтбордистка на земле
        if let velocityY = skater.physicsBody?.velocity.dy {
            if velocityY < -100.0 || velocityY > 100.0 {
                skater.isOnGround = false
            }
        }
        // Проверяем, должна ли игра закончиться
        let isOffScreen = skater.position.y < 0.0 || skater.position.x < 0.0
        let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0))
        let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation
        if isOffScreen || isTippedOver {
            gameOver()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        // Медленно увеличиваем значение scrollSpeed по мере развития игры
        scrollSpeed += 0.01
        
        // Определяем время, прошедшее с момента последнего вызова update
        var elapsedTime: TimeInterval = 0.0
        
        if let lastTimeStamp = lastUpdateTime {
            elapsedTime = currentTime - lastTimeStamp
        }
        lastUpdateTime = currentTime
        let expectedElapsedTime: TimeInterval = 1.0 / 60.0
        // Рассчитываем, насколько далеко должны сдвинуться объекты при данном обновлении
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
        let currentScrollAmount = scrollSpeed * scrollAdjustment
        updateBricks(withScrollAmount: currentScrollAmount)
        updateSkater()
        updateGems(withScrollAmount: currentScrollAmount)
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        // Заставляем скейтбордистку прыгнуть нажатием на экран, 8 пока она находится на земле
        if skater.isOnGround {
            skater.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
        }
    }
    // MARK:- SKPhysicsContactDelegate Methods
    func didBegin(_ contact: SKPhysicsContact) {
        // Проверяем, есть ли контакт между скейтбордисткой и секцией
        if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            skater.isOnGround = true
        } else if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.gem {
            // Скейтбордистка коснулась алмаза, поэтому мы его убираем
            if let gem = contact.bodyB.node as? SKSpriteNode {
                removeGem(gem)
            }
        }
    }
}
