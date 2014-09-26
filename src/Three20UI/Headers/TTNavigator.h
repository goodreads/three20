//
// Copyright 2009-2011 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Three20UINavigator/TTBaseNavigator.h"

/**
 * This function is no longer defined in Three20, in order to allow clients to
 * use their own navigation mechanism while they move away from Three20.
 * Simply define this function in the client code, using your own routing
 * shortcut.
 */
extern UIViewController* TTOpenURL(NSString* URL);

/**
 * This function is no longer defined in Three20, in order to allow clients to
 * use their own navigation mechanism while they move away from Three20.
 * Simply define this function in the client code, using your own routing
 * shortcut.
 */
extern UIViewController* TTOpenURLFromView(NSString* URL, UIView* view);

/**
 * A URL-based navigation system with built-in persistence.
 * Add support for model-based controllers and implement the legacy global instance accessor.
 */
@interface TTNavigator : TTBaseNavigator {
}

+ (TTNavigator*)navigator;

/**
 * Reloads the content in the visible view controller.
 */
- (void)reload;

@end
