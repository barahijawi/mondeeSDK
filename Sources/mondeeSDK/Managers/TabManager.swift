//
//  BrowserTabManager.swift
//  iOS-Web-Browser
//
//  Created by Sam Doggett on 3/24/21.
//

import UIKit

// MARK: TabManager - Manages the current tabs throughout the app
@objcMembers public class TabManager: NSObject {
    var tabs = [Tab]()
    var selectedTabIndex: Int

    var selectedTab: Tab {
        get {
            return tabs[selectedTabIndex]
        }
    }
    
    // Default page to direct user to
    let homePage = "https://beige-albina-80.tiiny.site"
    
   public override init(){
        let defaultTab = Tab(index: 0, homePage: homePage)
        selectedTabIndex = 0
        tabs.append(defaultTab)
    }
    
    func newTab(url :String) {
        // Append the new tab to the end of the tabs array
        let index = tabs.count
        
        let newTab = Tab(index: index, homePage: url)
        tabs.append(newTab)
        
        selectedTabIndex = index
    }
}
