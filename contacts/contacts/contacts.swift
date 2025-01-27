//
//  contacts.swift
//  contacts
//
//  Created by Stra1 T on 05.01.25.
//

import Foundation

import UIKit

class Contact {
    var name: String
    var phoneNumber: String

    init(name: String, phoneNumber: String) {
        self.name = name
        self.phoneNumber = phoneNumber
    }
}

class ViewController: UIViewController {
    private var contacts: [String: [Contact]] = [:] // Contacts grouped by first letter
    private var sections: [String] {
        return contacts.keys.sorted()
    }
    private var collapsedSections: Set<String> = [] // Track collapsed sections
    private var isGridLayout = false // Track the current layout

    private let tableView = UITableView()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.headerReferenceSize = CGSize(width: 100, height: 30)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private let addButton = UIBarButtonItem()
    private let layoutToggleButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Contacts"
        view.backgroundColor = .systemBackground

        // Add button
        addButton.image = UIImage(systemName: "plus")
        addButton.target = self
        addButton.action = #selector(showAddContactForm)
        navigationItem.leftBarButtonItem = addButton

        // Layout toggle button
        layoutToggleButton.image = UIImage(systemName: "list.bullet")
        layoutToggleButton.target = self
        layoutToggleButton.action = #selector(toggleLayout)
        navigationItem.rightBarButtonItem = layoutToggleButton

        // TableView setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // CollectionView setup
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ContactCell")
        collectionView.isHidden = true
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            CollectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CollectionHeaderView.reuseIdentifier
        )

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        addContact(name: "Nika", phoneNumber: "1234")
        addContact(name: "Lika", phoneNumber: "234")
        addContact(name: "Nana", phoneNumber: "599")
        addContact(name: "Luka", phoneNumber: "557")
        addContact(name: "Cxaura", phoneNumber: "arvici")
        addContact(name: "Nene", phoneNumber: "555")
    }

    @objc private func toggleLayout() {
        isGridLayout.toggle()
        layoutToggleButton.image = UIImage(systemName: isGridLayout ? "square.grid.2x2" : "list.bullet")
        tableView.isHidden = isGridLayout
        collectionView.isHidden = !isGridLayout
    }

    @objc private func showAddContactForm() {
        let alert = UIAlertController(title: "Add Contact", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Name" }
        alert.addTextField { $0.placeholder = "Phone Number"; $0.keyboardType = .phonePad }

        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard
                let name = alert.textFields?[0].text, !name.isEmpty,
                let phoneNumber = alert.textFields?[1].text, !phoneNumber.isEmpty
            else { return }
            self?.addContact(name: name, phoneNumber: phoneNumber)
        }
        addAction.isEnabled = false

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)

        alert.textFields?.forEach { textField in
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { _ in
                addAction.isEnabled = alert.textFields?.allSatisfy { !$0.text!.isEmpty } == true
            }
        }

        present(alert, animated: true)
    }

    private func addContact(name: String, phoneNumber: String) {
        let key = String(name.prefix(1)).uppercased()
        if contacts[key] == nil {
            contacts[key] = []
        }
        contacts[key]?.append(Contact(name: name, phoneNumber: phoneNumber))
        contacts[key]?.sort { $0.name < $1.name }
        tableView.reloadData()
        collectionView.reloadData()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = sections[section]
        return collapsedSections.contains(key) ? 0 : (contacts[key]?.count ?? 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let key = sections[indexPath.section]
        if let contact = contacts[key]?[indexPath.row] {
            cell.textLabel?.text = "\(contact.name)\n\(contact.phoneNumber)"
            cell.textLabel?.numberOfLines = 0
        }
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let key = sections[indexPath.section]
            contacts[key]?.remove(at: indexPath.row)
            if contacts[key]?.isEmpty == true {
                contacts.removeValue(forKey: key)
            }
            tableView.reloadData()
        }
    }
    
    

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGray5

        let label = UILabel()
        label.text = sections[section]
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)

        let button = UIButton(type: .system)
        button.setTitle(collapsedSections.contains(sections[section]) ? "Expand" : "Collapse", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(button)
        button.tag = section
        button.addTarget(self, action: #selector(toggleSection), for: .touchUpInside)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            button.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])

        return headerView
    }

    @objc private func toggleSection(_ sender: UIButton) {
        let section = sender.tag
        let key = sections[section]
        if collapsedSections.contains(key) {
            collapsedSections.remove(key)
        } else {
            collapsedSections.insert(key)
        }
        tableView.reloadSections([section], with: .automatic)
        collectionView.reloadSections(IndexSet(integer: section))
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
       
        let delete = UIContextualAction(
            style: .normal, title: "Delete", handler: { [unowned self]_,_,_ in deleteContact(at: indexPath)}
        )
        delete.backgroundColor = .red
        let actions: [UIContextualAction] = [
            delete
        ]
        let config = UISwipeActionsConfiguration(actions: actions)
        config.performsFirstActionWithFullSwipe = true
        return config
    }
}


class CollectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "CollectionHeaderView"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let toggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Collapse", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGray5
        addSubview(titleLabel)
        addSubview(toggleButton)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            toggleButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            toggleButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deleteContact(at: indexPath)
    }
    
    func collectionView(_ collectiomView: UICollectionView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let key = sections[section]
        return collapsedSections.contains(key) ? 0 : (contacts[key]?.count ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let key = sections[indexPath.section]
            contacts[key]?.remove(at: indexPath.row)
            if contacts[key]?.isEmpty == true {
                contacts.removeValue(forKey: key)
            }
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let key = sections[indexPath.section]
        if let contact = contacts[key]?[indexPath.row] {
            let label = UILabel(frame: cell.contentView.bounds)
            label.text = "\(contact.name)\n\(contact.phoneNumber)"
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 14)
            label.backgroundColor = .systemGray6
            label.layer.cornerRadius = 5
            label.clipsToBounds = true
            cell.contentView.addSubview(label)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            fatalError("Unexpected element kind")
        }
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionHeaderView.reuseIdentifier, for: indexPath) as! CollectionHeaderView
        let sectionKey = sections[indexPath.section]
        header.titleLabel.text = sectionKey
        header.toggleButton.setTitle(collapsedSections.contains(sectionKey) ? "Expand" : "Collapse", for: .normal)
        header.toggleButton.tag = indexPath.section
        header.toggleButton.addTarget(self, action: #selector(toggleSectionCollection(_:)), for: .touchUpInside)
        return header
    }

    @objc private func toggleSectionCollection(_ sender: UIButton) {
        let section = sender.tag
        let key = sections[section]
        if collapsedSections.contains(key) {
            collapsedSections.remove(key)
        } else {
            collapsedSections.insert(key)
        }
        collectionView.reloadSections(IndexSet(integer: section))
        tableView.reloadSections([section], with: .automatic)
    }
}


extension ViewController {
    func deleteContact(at indexPath: IndexPath){
        
        
        if(contacts[sections[indexPath.section]]?.count == 1){
            contacts.remove(at: contacts.index(forKey: sections[indexPath.section])!)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
            collectionView.deleteSections(IndexSet(integer: indexPath.section))
        }else{
            contacts[sections[indexPath.section]]?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            collectionView.deleteItems(at:  [indexPath])
        }
        collectionView.reloadData()
        tableView.reloadData()

    }
}
