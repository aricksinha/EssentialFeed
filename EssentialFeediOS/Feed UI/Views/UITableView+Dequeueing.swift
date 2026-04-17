//
//  UITableView+Dequeueing.swift
//  EssentialFeediOS
//
//  Created by Aritra on 16/04/26.
//

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        return dequeueReusableCell(withIdentifier: identifier) as! T
    }
}
