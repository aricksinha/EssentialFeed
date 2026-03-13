import UIKit

struct FeedImageViewModel {
    let description: String?
    let imageName: String
}

final class FeedViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Feed"

        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = 520
        tableView.estimatedRowHeight = 520
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FeedImageCell", for: indexPath) as? FeedImageCell else {
            return UITableViewCell()
        }
        cell.locationLabel.text = "Location, Location"
        return cell
    }
}
