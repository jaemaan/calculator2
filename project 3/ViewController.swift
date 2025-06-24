import UIKit

class ViewController: UIViewController {
    
    var expressionText: String = ""
    
    let expressionLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .black
        label.textColor = .white
        label.textAlignment = .right
        label.font = UIFont.boldSystemFont(ofSize: 60)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        setupExpressionLabel()
        setupVerticalStackView()
    }
    
    private func setupExpressionLabel() {
        view.addSubview(expressionLabel)
        NSLayoutConstraint.activate([
            expressionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            expressionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            expressionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            expressionLabel.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func makeButton(titleValue: String, action: Selector, backgroundColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(titleValue, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 30)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 40
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 80),
            button.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        return button
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        
        switch title {
        case "=":
            let exp = NSExpression(format: expressionText)
            if let result = exp.expressionValue(with: nil, context: nil) as? NSNumber {
                expressionLabel.text = result.stringValue
                expressionText = result.stringValue
            } else {
                expressionLabel.text = "Error"
                expressionText = ""
            }
            
        case "AC":
            expressionText = ""
            expressionLabel.text = ""
            
        default:
            expressionText += title
            expressionLabel.text = expressionText
        }
    }
    
    private func setupVerticalStackView() {
        let gray = UIColor(red: 58/255, green: 58/255, blue: 58/255, alpha: 1.0)
        let orange = UIColor.orange
        
        let rows: [[(String, UIColor)]] = [
            [("1", gray), ("2", gray), ("3", gray), ("+", orange)],
            [("4", gray), ("5", gray), ("6", gray), ("-", orange)],
            [("7", gray), ("8", gray), ("9", gray), ("*", orange)],
            [("0", gray), ("AC", orange), ("=", orange), ("/", orange)]
        ]
        
        let rowStackViews = rows.map { row -> UIStackView in
            let buttons = row.map { makeButton(titleValue: $0.0, action: #selector(buttonTapped), backgroundColor: $0.1) }
            let hStack = UIStackView(arrangedSubviews: buttons)
            hStack.axis = .horizontal
            hStack.spacing = 10
            hStack.distribution = .fillEqually
            hStack.backgroundColor = .black
            return hStack
        }
        
        let verticalStackView = UIStackView(arrangedSubviews: rowStackViews)
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 10
        verticalStackView.distribution = .fillEqually
        verticalStackView.backgroundColor = .black
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(verticalStackView)
        
        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: expressionLabel.bottomAnchor, constant: 60),
            verticalStackView.widthAnchor.constraint(equalToConstant: 350),
            verticalStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
let numbers4 = [10,3,5,1,6]
let result4 = numbers4.sorted { left,right in
    left < right
}
