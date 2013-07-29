#import "HelloWorldLayer.h"

@implementation HelloWorldLayer

+ (id)scene {
    
    CCScene *scene = [CCScene node];
    HelloWorldLayer *layer = [HelloWorldLayer node];
    [scene addChild:layer];
    return scene;
    
}

- (id)init {
    
    if ((self=[super init])) {
        
        [self setTouchEnabled:YES];
        
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"ticks.wav"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"ting.wav"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"gameover.wav"];

        CGSize winSize = [CCDirector sharedDirector].winSize;
        float width = winSize.width;
        float height = winSize.height;
        
        screenWidth = winSize.width;
        screenHeight = winSize.height;
        CCLabelTTF * kickBallLabel = [CCLabelTTF labelWithString:@"Start" fontName:@"Arial" fontSize:32];
        CCMenuItemLabel * kickBall = [CCMenuItemLabel itemWithLabel: kickBallLabel target: self selector : @selector(kick:)];
        CCMenu * menu = [CCMenu menuWithItems:kickBall, nil];
        menu.position =  ccp( width/2 , height/2 );
        [self addChild:menu];
        // Create sprite and add it to the layer
        _ball = [CCSprite spriteWithFile:@"ball.png" rect:CGRectMake(0, 0, 52, 52)];
        _ball.position = ccp(width - 100.0, height/2.0);
        
        _lpaddle = [CCSprite spriteWithFile:@"paddle.png"];
        _rpaddle = [CCSprite spriteWithFile:@"paddle.png"];
        
        _lpaddle.position = ccp(50.0, height/2);
        _rpaddle.position = ccp(width - 50.0, height/2);
        
        [self addChild:_lpaddle];
        [self addChild:_rpaddle];
        [self addChild:_ball];
        [_lpaddle runAction:[CCMoveTo actionWithDuration:1 position:ccp(500,600)]];
         [self schedule:@selector(nextFrame:)];
    
        // Create a world
        b2Vec2 gravity = b2Vec2(0.0f, 0.0f);
        _world = new b2World(gravity);
        
        // Create edges around the entire screen
        b2BodyDef tfgroundBodyDef;
        tfgroundBodyDef.position.Set(0,0);
     
        b_tfgroundBody = _world->CreateBody(&tfgroundBodyDef);
        b2EdgeShape tfgroundEdge;
        b2FixtureDef tfboxShapeDef;
        tfboxShapeDef.shape = &tfgroundEdge;
        
        b2BodyDef lrgroundBodyDef;
        lrgroundBodyDef.position.Set(0,0);
        
        
        b_lrgroundBody = _world->CreateBody(&lrgroundBodyDef);
        b2EdgeShape lrgroundEdge;
        b2FixtureDef lrboxShapeDef;
        lrboxShapeDef.shape = &lrgroundEdge;

        
        //wall definitions
        tfgroundEdge.Set(b2Vec2(0,0), b2Vec2(winSize.width/PTM_RATIO, 0)); // bottom walls
        b_tfgroundBody->CreateFixture(&tfboxShapeDef);
        
        tfgroundEdge.Set(b2Vec2(0, winSize.height/PTM_RATIO),
                         b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO)); // top wall
        b_tfgroundBody->CreateFixture(&tfboxShapeDef);
        
        

        
        lrgroundEdge.Set(b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO), // right wall
                       b2Vec2(winSize.width/PTM_RATIO, 0));
        b_lrgroundBody->CreateFixture(&lrboxShapeDef);
        
        lrgroundEdge.Set(b2Vec2(0,0), b2Vec2(0,winSize.height/PTM_RATIO)); // left wall
        b_lrgroundBody->CreateFixture(&lrboxShapeDef);
        
        // Create ball body and shape
        b2BodyDef ballBodyDef;
        ballBodyDef.type = b2_dynamicBody;
        ballBodyDef.position.Set((width - 100)/PTM_RATIO, (height/2.0)/PTM_RATIO);
        
        ballBodyDef.userData = _ball;
        b_ball = _world->CreateBody(&ballBodyDef);
        
        b2CircleShape circle;
        circle.m_radius = 26.0/PTM_RATIO;
        
        b2FixtureDef ballShapeDef;
        ballShapeDef.shape = &circle;
        ballShapeDef.density = 1.0f;
        ballShapeDef.friction = 0.f;
        ballShapeDef.restitution = 1.0f;
        b_ball->CreateFixture(&ballShapeDef);
        
        // Create left paddle and right paddle bodies
     
        b2BodyDef lPaddleBodyDef;
        
        lPaddleBodyDef.position.Set(50.0/PTM_RATIO, height/2.0/PTM_RATIO);
        lPaddleBodyDef.userData = _lpaddle;
        lPaddleBodyDef.type = b2_dynamicBody;

        b_lpaddle = _world->CreateBody(&lPaddleBodyDef);
        
        b2PolygonShape lboxShape;
        lboxShape.SetAsBox(20.0/PTM_RATIO, 75.0/PTM_RATIO);
        
        b2FixtureDef lPaddleShapeDef;
        lPaddleShapeDef.shape = &lboxShape;
        lPaddleShapeDef.density = 1.0f;
        lPaddleShapeDef.friction = 0.2f;
        lPaddleShapeDef.restitution = 0.8f;
        _lpaddleFixture = b_lpaddle->CreateFixture(&lPaddleShapeDef);
       
        // Create left paddle and right paddle bodies
        
        b2BodyDef rPaddleBodyDef;
        rPaddleBodyDef.position.Set((width-50.0)/PTM_RATIO, height/2.0/PTM_RATIO);
        rPaddleBodyDef.userData = _rpaddle;
        rPaddleBodyDef.type = b2_dynamicBody;

        b_rpaddle = _world->CreateBody(&rPaddleBodyDef);
        
        b2PolygonShape rBoxShape;
        rBoxShape.SetAsBox(20.0/PTM_RATIO, 75.0/PTM_RATIO);
        
        b2FixtureDef rPaddleShapeDef;
        rPaddleShapeDef.shape = &rBoxShape;
        rPaddleShapeDef.density = 1.0f;
        rPaddleShapeDef.friction = 0.2f;
        rPaddleShapeDef.restitution = 0.8f;
        _rpaddleFixture = b_rpaddle->CreateFixture(&rPaddleShapeDef);
        
        [self schedule:@selector(tick:)];

        // Restrict paddle along the x axis
        b2PrismaticJointDef l_jointDef;
        b2Vec2 worldAxis(0.0f, 1.0f);
        l_jointDef.collideConnected = true;
        l_jointDef.Initialize(b_lpaddle, b_tfgroundBody,
                              b_lpaddle->GetWorldCenter(), worldAxis);
        _world->CreateJoint(&l_jointDef);
        
        b2PrismaticJointDef r_jointDef;
        r_jointDef.collideConnected = true;
        r_jointDef.Initialize(b_rpaddle, b_lrgroundBody,
                              b_rpaddle->GetWorldCenter(), worldAxis);
        _world->CreateJoint(&r_jointDef);
        
        _contactListener = new MyContactListener();
        _world->SetContactListener(_contactListener);
        
    }
    return self;
}

- (void) nextFrame:(ccTime)dt {
    _lpaddle.position = ccp( _lpaddle.position.x + 100*dt, _lpaddle.position.y );
    if (_lpaddle.position.x > 480+32) {
        _lpaddle.position = ccp( -32, _lpaddle.position.y );
    }
}
/*

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    // Landscape left values
    b2Vec2 gravity(acceleration.y * 30, -acceleration.x * 30);
    _world->SetGravity(gravity);
}
*/
float threshold = 0.5;

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;{
  //  b2Vec2 force = b2Vec2(-30, 30);
 //   b_ball->ApplyLinearImpulse(force, b_ball->GetPosition());
    NSSet *allTouches = [event allTouches];
    BOOL left = false;
    BOOL right = false;
    for (UITouch* touch in allTouches) {
        CGPoint location = [self convertTouchToNodeSpace: touch];
        b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
        
        if (left && right) return;
        if (!left && location.x < screenWidth * threshold && _lpaddleFixture->TestPoint(locationWorld) && l_mouseJoint == NULL) {
            b_lpaddle->GetFixtureList();
            b2MouseJointDef md;
            md.bodyA = b_tfgroundBody;
            md.bodyB = b_lpaddle;
            md.target = locationWorld;
            md.collideConnected = true;
            md.maxForce = 1000.0f * b_lpaddle->GetMass();
                        assert(l_mouseJoint == NULL);
            l_mouseJoint = (b2MouseJoint *)_world->CreateJoint(&md);
            b_lpaddle->SetAwake(true);
            left = true;
        }
        else if (!right && location.x > screenWidth * (1-threshold) && _rpaddleFixture->TestPoint(locationWorld) && r_mouseJoint == NULL) {
            b_rpaddle->GetFixtureList();
            b2MouseJointDef md;
            md.bodyA = b_tfgroundBody;
            md.bodyB = b_rpaddle;
            md.target = locationWorld;
            md.collideConnected = true;
            md.maxForce = 1000.0f * b_rpaddle->GetMass();
            assert(r_mouseJoint == NULL);
            r_mouseJoint = (b2MouseJoint *)_world->CreateJoint(&md);
            b_rpaddle->SetAwake(true);
            right = true;
        }
    }

}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    BOOL left = false;
    BOOL right = false;
    if (l_mouseJoint == NULL && r_mouseJoint == NULL) return;
    NSSet *allTouches = [event allTouches];

    for (UITouch* touch in allTouches) {
        if (left && right) return;
        CGPoint location = [self convertTouchToNodeSpace: touch];

        if (!left && location.x < screenWidth * threshold && l_mouseJoint != NULL){
            
            b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
            l_mouseJoint->SetTarget(locationWorld);
            left = true;
        }
        else if (!right && location.x > screenWidth * (1-threshold) && r_mouseJoint != NULL){
            
            b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
            r_mouseJoint->SetTarget(locationWorld);
            right = true;
        }
    }
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches = [event allTouches];

    for (UITouch* touch in allTouches) {
        CGPoint location = [self convertTouchToNodeSpace: touch];
        
        if (location.x < screenWidth * threshold && l_mouseJoint) {
            _world->DestroyJoint(l_mouseJoint);
            l_mouseJoint = NULL;
        }
        else if (location.x > screenWidth * (1-threshold) && r_mouseJoint ){
            _world->DestroyJoint(r_mouseJoint);
            r_mouseJoint = NULL;
        }
    }
    
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches = [event allTouches];
    
    for (UITouch* touch in allTouches) {
        CGPoint location = [self convertTouchToNodeSpace: touch];
        
        if (location.x < screenWidth * threshold && l_mouseJoint) {
            _world->DestroyJoint(l_mouseJoint);
            l_mouseJoint = NULL;
        }
        else if (location.x > screenWidth * (1-threshold) && r_mouseJoint ){
            _world->DestroyJoint(r_mouseJoint);
            r_mouseJoint = NULL;
        }
    }
    
}


- (void)kick: (CCMenuItemLabel *) item {
    b2Vec2 force = b2Vec2(-50, 30);
    b_ball->ApplyLinearImpulse(force,b_ball->GetPosition());
        
}

- (void) reset{
    NSLog(@"Game Over");
    b_ball->SetLinearVelocity(b2Vec2(0,0));
    b_ball->SetAngularVelocity(0);

    b_ball->SetTransform(b2Vec2((screenWidth - 100)/PTM_RATIO, (screenHeight/2.0)/PTM_RATIO), 0);
    
}

- (void)tick:(ccTime) dt {
    
    _world->Step(dt, 10, 10);
    for(b2Body *b = _world->GetBodyList(); b; b=b->GetNext()) {
        if (b->GetUserData() != b_ball) {
            CCSprite *ballData = (CCSprite *)b->GetUserData();
            ballData.position = ccp(b->GetPosition().x * PTM_RATIO,
                                    b->GetPosition().y * PTM_RATIO);
            ballData.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
            
            static int maxSpeed = 70;
            
            b2Vec2 velocity = b_ball->GetLinearVelocity();
            float32 speed = velocity.Length();
            
            if (speed > maxSpeed) {
                b_ball->SetLinearDamping(0.2);
            } else if (speed < maxSpeed) {
                b_ball->SetLinearDamping(0.0);
            }
            

        }
    }
    
    //check contacts
    std::vector<MyContact>::iterator pos;
    for(pos = _contactListener->_contacts.begin();
        pos != _contactListener->_contacts.end(); ++pos) {
        MyContact contact = *pos;
        
        if ((contact.fixtureA == b_ball->GetFixtureList() && contact.fixtureB == b_rpaddle->GetFixtureList()) ||
            (contact.fixtureA == b_rpaddle->GetFixtureList() && contact.fixtureB == b_ball->GetFixtureList())||(contact.fixtureA == b_ball->GetFixtureList() && contact.fixtureB == b_lpaddle->GetFixtureList()) ||
            (contact.fixtureA == b_lpaddle->GetFixtureList() && contact.fixtureB == b_ball->GetFixtureList())) {
            NSLog(@"Ball hit a paddle!");
            [[SimpleAudioEngine sharedEngine] playEffect: @"ting.wav"];

        }
        else {
            
            for (b2Fixture* f = b_lrgroundBody->GetFixtureList(); f; f = f->GetNext())
            {
                if ((contact.fixtureA == b_ball->GetFixtureList() && contact.fixtureB == f) ||
                    (contact.fixtureA == f && contact.fixtureB == b_ball->GetFixtureList())) {
                    
                    [[SimpleAudioEngine sharedEngine] playEffect: @"gameover.wav"];
                    [self reset];
                }
            }
            for (b2Fixture* f = b_tfgroundBody->GetFixtureList(); f; f = f->GetNext())
            {
                if ((contact.fixtureA == b_ball->GetFixtureList() && contact.fixtureB == f) ||
                    (contact.fixtureA == f && contact.fixtureB == b_ball->GetFixtureList())) {
                    
                    [[SimpleAudioEngine sharedEngine] playEffect: @"ticks.wav"];
                }
            }

        }
    }
    
}


- (void)dealloc {
    delete _contactListener;
    delete _world;
    b_ball = NULL;
    b_lpaddle = NULL;
    b_rpaddle = NULL;
    _world = NULL;
    
    [super dealloc];
}

@end