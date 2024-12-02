import SwiftUI

// MODEL
struct Contact: Identifiable, Codable {
    let id: UUID = UUID()
    var name: String
    var phoneNumber: String
    var email: String
    var address: String
}

// VIEW-MODEL
class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var searchQuery: String = ""
    
    private let fileName = "contacts.json"
    
    init() {
        loadContacts()
    }
    
    // Add a contact
    func addContact(name: String, phoneNumber: String, email: String, address: String) {
        let newContact = Contact(name: name, phoneNumber: phoneNumber, email: email, address: address)
        contacts.append(newContact)
        saveContacts()
    }
    
    // Edit a contact
    func editContact(contact: Contact, newName: String, newPhoneNumber: String, newEmail: String, newAddress: String) {
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index].name = newName
            contacts[index].phoneNumber = newPhoneNumber
            contacts[index].email = newEmail
            contacts[index].address = newAddress
        }
        saveContacts()
    }
    
    // Delete a contact
    func deleteContact(contact: Contact) {
        contacts.removeAll { $0.id == contact.id }
        saveContacts()
    }
    
    // Filtered contacts for search
    var searchContacts: [Contact] {
        if searchQuery.isEmpty {
            return contacts
        } else {
            return contacts.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
        }
    }
    
    // Save contacts to file
    private func saveContacts() {
        if let url = getFileURL() {
            do {
                let data = try JSONEncoder().encode(contacts)
                try data.write(to: url)
            } catch {
                print("Failed to save contacts: \(error.localizedDescription)")
            }
        }
    }
    
    // Load contacts from file
    private func loadContacts() {
        if let url = getFileURL() {
            do {
                let data = try Data(contentsOf: url)
                contacts = try JSONDecoder().decode([Contact].self, from: data)
            } catch {
                print("Failed to load contacts: \(error.localizedDescription)")
            }
        }
    }
    
    private func getFileURL() -> URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentDirectory?.appendingPathComponent(fileName)
    }
}

// SETTINGS VIEW-MODEL
class SettingsViewModel: ObservableObject {
    @Published var fontSize: Double {
        didSet { saveSettings() }
    }
    @Published var backgroundColor: Color {
        didSet { saveSettings() }
    }
    
    init() {
        self.fontSize = UserDefaults.standard.double(forKey: "fontSize") == 0 ? 14 : UserDefaults.standard.double(forKey: "fontSize")
        if let colorData = UserDefaults.standard.data(forKey: "backgroundColor"),
           let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
            self.backgroundColor = Color(uiColor)
        } else {
            self.backgroundColor = .white
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
        if let uiColor = UIColor(backgroundColor) {
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
                UserDefaults.standard.set(colorData, forKey: "backgroundColor")
            }
        }
    }
}

// VIEW
struct ContentView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var isAddingContact = false
    @State private var isShowingSettings = false
    @State private var currentContact: Contact?
    @State private var newContactName = ""
    @State private var newContactPhone = ""
    @State private var newContactEmail = ""
    @State private var newContactAddress = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Пошук:", text: $viewModel.searchQuery)
                    .padding()
                    .font(.system(size: settingsViewModel.fontSize))
                
                List {
                    ForEach(viewModel.searchContacts) { contact in
                        HStack {
                            Text(contact.name)
                                .font(.system(size: settingsViewModel.fontSize))
                            Spacer()
                            Button(action: { editContact(contact) }) {
                                Text("редагувати")
                                    .foregroundColor(.orange)
                            }
                            Button(action: { viewModel.deleteContact(contact: contact) }) {
                                Text("видалити")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Button(action: {
                    isAddingContact = true
                    resetTempFields()
                }) {
                    Text("Додати новий контакт")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $isAddingContact) {
                    changeContactView
                }
            }
            .padding()
            .background(settingsViewModel.backgroundColor)
            .navigationTitle("Контакти")
            .toolbar {
                Button(action: { isShowingSettings = true }) {
                    Text("*")
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView(settingsViewModel: settingsViewModel)
                }
            }
        }
    }
    
    var changeContactView: some View {
        VStack {
            Text("Ім'я:")
                .font(.title)
                .padding()
            TextField("Ім'я", text: $newContactName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("Номер телефону:")
                .font(.title)
                .padding()
            TextField("Номер телефону", text: $newContactPhone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("Електронна пошта:")
                .font(.title)
                .padding()
            TextField("Електронна пошта", text: $newContactEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("Адреса:")
                .font(.title)
                .padding()
            TextField("Адреса", text: $newContactAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                if let contact = currentContact {
                    viewModel.editContact(contact: contact, newName: newContactName, newPhoneNumber: newContactPhone, newEmail: newContactEmail, newAddress: newContactAddress)
                } else {
                    viewModel.addContact(name: newContactName, phoneNumber: newContactPhone, email: newContactEmail, address: newContactAddress)
                }
                isAddingContact = false
                currentContact = nil
            }) {
                Text(currentContact == nil ? "Додати контакт" : "Оновити контакт")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
    
    private func editContact(_ contact: Contact) {
        newContactName = contact.name
        newContactPhone = contact.phoneNumber
        newContactEmail = contact.email
        newContactAddress = contact.address
        currentContact = contact
        isAddingContact = true
    }
    
    private func resetTempFields() {
        newContactName = ""
        newContactPhone = ""
        newContactEmail = ""
        newContactAddress = ""
        currentContact = nil
    }
}

struct SettingsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Розмір шрифту")) {
                Slider(value: $settingsViewModel.fontSize, in: 10...30, step: 1) {
                    Text("Розмір шрифту")
                }
                Text("Розмір шрифту: \(Int(settingsViewModel.fontSize))")
            }
            
            Section(header: Text("Колір фону")) {
                ColorPicker("Оберіть колір", selection: $settingsViewModel.backgroundColor)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
