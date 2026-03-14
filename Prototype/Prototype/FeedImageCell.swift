import UIKit

final class FeedImageCell: UITableViewCell {
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var feedImageView: UIImageView!
}

extension FeedImageCell {
    func ocnfigure(_ model: FeedImageViewModel) {
        descriptionLabel.text = model.description
        descriptionLabel.isHidden = model.description == nil
        feedImageView.image = UIImage(named: model.imageName)
    }
}
