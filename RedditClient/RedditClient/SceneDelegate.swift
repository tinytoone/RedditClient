//
//  SceneDelegate.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)

        if let activity = connectionOptions.userActivities.first ?? session.stateRestorationActivity, activity.activityType == Constants.StateRestoration.FullImageRestorationType {
            self.window?.rootViewController = restorationRootViewController(userActivity: activity)
        } else {
            self.window?.rootViewController = noRestorationRootViewController()
        }

        self.window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) { }

    func sceneDidBecomeActive(_ scene: UIScene) { }

    func sceneWillResignActive(_ scene: UIScene) { }

    func sceneWillEnterForeground(_ scene: UIScene) { }

    func sceneDidEnterBackground(_ scene: UIScene) { }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        if let nc = self.window?.rootViewController as? UINavigationController, let vc = nc.viewControllers.last as? RestorableViewController {
            return vc.continuationActivity
        } else {
            return nil
        }
    }
    
    func restorationRootViewController(userActivity: NSUserActivity) -> UIViewController {
        let postsListTableViewController = UIStoryboard(name: Constants.StoryboardId.PostsList, bundle: Bundle.main).instantiateInitialViewController() as! PostsListTableViewController
        postsListTableViewController.viewModel = RedditPostsListViewModel(apiClient: RedditAPIClient(), imageDownloader: RedditImageDownloader(urlCache: URLCache.shared))

        let navigationController = UINavigationController(rootViewController: postsListTableViewController)
        let fullImageViewController = UIStoryboard(name: Constants.StoryboardId.FullImage, bundle: Bundle.main).instantiateInitialViewController() as! FullImageViewController
        fullImageViewController.viewModel = RedditFullImageViewModel.restoreFrom(userActivity: userActivity) as? FullImageViewModel
        
        navigationController.pushViewController(fullImageViewController, animated: false)
        navigationController.navigationBar.isTranslucent = false
        navigationController.restorationIdentifier = Constants.StateRestoration.RootNavigationControllerId
        return navigationController
    }
    
    func noRestorationRootViewController() -> UIViewController {
        let postsListTableViewController = UIStoryboard(name: Constants.StoryboardId.PostsList, bundle: Bundle.main).instantiateInitialViewController() as! PostsListTableViewController
        postsListTableViewController.viewModel = RedditPostsListViewModel(apiClient: RedditAPIClient(), imageDownloader: RedditImageDownloader(urlCache: URLCache.shared))

        let navigationController = UINavigationController(rootViewController: postsListTableViewController)
        navigationController.navigationBar.isTranslucent = false
        navigationController.restorationIdentifier = Constants.StateRestoration.RootNavigationControllerId
        return navigationController
    }

}

