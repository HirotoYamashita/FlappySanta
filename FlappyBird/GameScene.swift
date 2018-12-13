//
//  GameScene.swift
//  FlappyBird
//
//  Created by Santa on 2018/11/28.
//  Copyright © 2018 HirotoYamashita. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var itemNode: SKNode!
    var turboItemNode: SKNode!
    var bird: SKSpriteNode!
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0     // 0...00001
    let groundCategory: UInt32 = 1 << 1   // 0...00010
    let wallCategory: UInt32 = 1 << 2     // 0...00100
    let scoreCategory: UInt32 = 1 << 3    // 0...01000
    let itemCategory: UInt32 = 1 << 4
    let turboCategory: UInt32 = 1 << 5
    
    // スコア
    var score = 0
    var score_item = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    
    // BGM音楽を設定
    let normalBgm = SKAudioNode(fileNamed: "jinglebell.mp3")
    let turboBgm = SKAudioNode(fileNamed: "turboBgm.mp3")
    
    // 効果音を設定
    let sound: SKAction = SKAction.playSoundFileNamed("itemGet.mp3", waitForCompletion: true)

    // 加速値
    var turbo: Double = 1.0
    
    // UserDefault
    let userDefaults:UserDefaults = UserDefaults.standard
    
    // SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        // BGMの再生
        turboBgm.run(SKAction.stop())
        addChild(normalBgm)
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0*turbo)
        physicsWorld.contactDelegate = self
        
        // 背景色を設定
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.30, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用ノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // アイテム用ノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        turboItemNode = SKNode()
        scrollNode.addChild(turboItemNode)
        
        setupCloud()
        setupGround()
        setupWall()
        setupBird()
        setupItem()
        setupTurboItem()
        
        setupScoreLabel()
    }
    
    
    // SKPhysicsContactDelegateのメソッド：衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // score用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        } else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            // スコア用の物体と衝突した
            score_item += 1
            itemScoreLabelNode.text = "Item Score:\(score_item)"
            
            // 効果音を鳴らす
            self.run(sound)
            
            // アイテムを消す
            itemNode.alpha = 0
            
            
        } else if (contact.bodyA.categoryBitMask & turboCategory) == turboCategory || (contact.bodyB.categoryBitMask & turboCategory) == turboCategory {
            // 効果音を鳴らす
            self.run(sound)
            
            // BGMを変更
            if normalBgm.isPaused == false {
                normalBgm.run(SKAction.stop())
                turboBgm.run(SKAction.play())
                
                // turboBgmが追加されていない時は追加する
                if turboBgm.parent == nil {
                    addChild(turboBgm)
                }
            }
            
            // アイテムを消す
            turboItemNode.alpha = 0
            
            turbo += 0.2
            wallNode.removeAllChildren()
            wallNode.removeAllActions()
            setupWall()
            
            itemNode.removeAllChildren()
            itemNode.removeAllActions()
            setupItem()
            
        } else {
            // 壁か地面と衝突した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if scrollNode.speed > 0 {
            // 鳥の速度を0にする
            bird.physicsBody?.velocity = CGVector.zero
            
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20*Int(turbo)))
        } else if bird.speed == 0 {
            restart()
        }
        
    }
        
    
    // リスタート
    func restart() {
    
         // BGMリスタート
        normalBgm.run(SKAction.stop())
        turboBgm.run(SKAction.stop())
        normalBgm.run(SKAction.play())
        
        score = 0
        score_item = 0
        scoreLabelNode.text = String("Score:\(score)")
        itemScoreLabelNode.text = String("Item Score:\(score_item)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        self.turbo = 1.0
        wallNode.removeAllChildren()
        wallNode.removeAllActions()
        setupWall()
        
        itemNode.removeAllChildren()
        itemNode.removeAllActions()
        setupItem()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
   
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.white
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        score_item = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.white
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score:\(score_item)"
        self.addChild(itemScoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.white
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestScoreLabelNode.text = "Score:\(score)"
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
    }
    
    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        // .nearest:処理優先　.linear:画質優先
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールをするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール＞元の位置＞左にスクロールと無限に繰り替えるアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width * (CGFloat(i) + 0.5),
                y: groundTexture.size().height * 0.5
            )
            
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリ設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "bacground")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向い画像を一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール＞元の位置＞左にスクロールと無限に繰り替えるアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // レイヤーが一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width * (CGFloat(i) + 0.5),
                y: self.size.height - cloudTexture.size().height * 0.5
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
        
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width*1.5)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:2/turbo)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0 // 雲より手前、地面より奥
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            // 壁のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4
            // 下の壁のY軸の下限
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 5
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないようにする
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory

            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2/turbo)
        
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupItem() {
        // アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "present")
        itemTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width*1.5)
        
        // 画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 2/turbo)
        
        //  自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // アイテムを作成するアクションを作成
        let createItemAnimation = SKAction.run({
            if self.itemNode.alpha == 0 {
                self.itemNode.alpha = 1
            }
            
            // アイテムのノードを乗せるノード
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
            item.zPosition = -51.0
            
            // アイテム配置の振り幅上限
            let range_y = self.frame.size.height / 3
            
            // 1~range_yまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(range_y))
            
            // アイテムのy軸をランダムに決定
            let item_y = CGFloat( UInt32(range_y) + random_y)
            
            // アイテムの表示位置を設定
            let itemSprite = SKSpriteNode(texture: itemTexture)
            itemSprite.position = CGPoint(x: 0.0, y: item_y)
            
            // スプライトに物理演算を設定する
            itemSprite.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
            itemSprite.physicsBody?.categoryBitMask = self.itemCategory
            itemSprite.physicsBody?.isDynamic = false
            
            // アイテムノードにスプライトを追加する
            item.addChild(itemSprite)
            
            // スコア用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: itemSprite.size.width, y: item_y)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: itemSprite.size.width/2, height: itemSprite.size.height/2))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.itemCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory

            item.addChild(scoreNode)
            
            // スプライトにアニメーションを設定する
            item.run(itemAnimation)
            
            self.itemNode.addChild(item)
        })
        
        // 次のアイテム作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 1/turbo)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([waitAnimation, createItemAnimation, waitAnimation]))
        
        itemNode.run(repeatForeverAnimation)
    }
    
    func setupTurboItem() {
        // アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "cherry")
        itemTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width*1.5)
        
        // 画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 2/turbo)
        
        //  自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // アイテムを作成するアクションを作成
        let createItemAnimation = SKAction.run({
            if self.turboItemNode.alpha == 0 {
                self.turboItemNode.alpha = 1
            }
            
            // アイテムのノードを乗せるノード
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
            item.zPosition = -51.0
            
            // アイテム配置の振り幅上限
            let range_y = self.frame.size.height / 3
            
            // 1~range_yまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(range_y))
            
            // アイテムのy軸をランダムに決定
            let item_y = CGFloat( UInt32(range_y) + random_y)
            
            // アイテムの表示位置を設定
            let itemSprite = SKSpriteNode(texture: itemTexture)
            itemSprite.position = CGPoint(x: 0.0, y: item_y)
            
            // スプライトに物理演算を設定する
            itemSprite.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
            itemSprite.physicsBody?.categoryBitMask = self.turboCategory
            itemSprite.physicsBody?.isDynamic = false
            
            // アイテムノードにスプライトを追加する
            item.addChild(itemSprite)
            
            // スコア用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: itemSprite.size.width, y: item_y)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: itemSprite.size.width, height: itemSprite.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.turboCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            item.addChild(scoreNode)
            
            // スプライトにアニメーションを設定する
            item.run(itemAnimation)
            
            self.turboItemNode.addChild(item)
        })
        
        // 次のアイテム作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 3/turbo)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([waitAnimation, createItemAnimation, waitAnimation]))
        
        turboItemNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // サンタの画像を読み込む
        let santaTextureA = SKTexture(imageNamed: "santa_a")
        santaTextureA.filteringMode = .linear
        let santaTextureB = SKTexture(imageNamed: "santa_b")
        santaTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texuresAnimation = SKAction.animate(with: [santaTextureA, santaTextureB], timePerFrame: 0.4)
        let flap = SKAction.repeatForever(texuresAnimation)
        
        // スプライトを設定
        bird = SKSpriteNode(texture: birdTextureA)
        bird.size = CGSize(width: bird.size.width*2, height: bird.size.height*2)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 3.0)
        
        // 衝突したときに回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突カテゴリーの設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
    }
    
    
    
}















