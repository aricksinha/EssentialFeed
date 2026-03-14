import UIKit

final class FeedImageCell: UITableViewCell {
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var feedImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        feedImageView.alpha = 0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        feedImageView.alpha = 0
    }
    
    func fadeIn(_ image: UIImage?) {
        feedImageView.image = image
        UIView.animate(
            withDuration: 0.3,
            delay: 0.3,
            options: [],
            animations: {
                self.feedImageView.alpha = 1
            })
    }
}

extension FeedImageCell {
    func ocnfigure(_ model: FeedImageViewModel) {
        descriptionLabel.text = model.description
        descriptionLabel.isHidden = model.description == nil
        fadeIn(UIImage(named: model.imageName))
    }
}
