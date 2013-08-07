#import "cocos2d.h"
#import "Box2D.h"
#import "MyContactListener.h"
#import "SimpleAudioEngine.h"
#import "MyMenuItemImage.h"

#define PTM_RATIO 32.0

@interface HelloWorldLayer : CCLayer {
    
    b2World *_world;
    b2Body *b_tfgroundBody;
    b2Body *b_lrgroundBody;
    b2Body *b_ball;
    b2Body *b_lpaddle;
    b2Body *b_rpaddle;
    b2Body *b_rBar;
    b2MouseJoint *l_mouseJoint;
    b2MouseJoint *r_mouseJoint;

    b2Fixture *_lpaddleFixture;
    b2Fixture *_rpaddleFixture;
    b2Fixture *_rBarFixture;
    CCSprite *_ball;
    CCSprite *_lpaddle;
    CCSprite *_rpaddle;
    CCSprite *_rbar;

    MyContactListener *_contactListener;
    float screenWidth;
    float screenHeight;
}

+ (id) scene;
- (void)kick;

@end