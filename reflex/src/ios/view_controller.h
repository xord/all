// -*- objc -*-
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


@interface ReflexView : GLKView
@end


@interface ReflexViewController : UIViewController

	@property(nonatomic, strong, readonly) ReflexView* reflexView;

	- (ReflexView*) createReflexView;

	- (void) startTimer;

	- (void) stopTimer;

	- (void) viewDidResize;

	- (void) titleDidChange;

@end// ReflexViewController


typedef ReflexViewController* (*ReflexViewController_CreateFun) ();

typedef void (*ReflexViewController_ShowFun) (
	UIViewController* root_vc, ReflexViewController* reflex_vc);


void ReflexViewController_set_create_fun (ReflexViewController_CreateFun fun);

void ReflexViewController_set_show_fun   (ReflexViewController_ShowFun   fun);

ReflexViewController_CreateFun ReflexViewController_get_create_fun ();

ReflexViewController_ShowFun   ReflexViewController_get_show_fun ();
