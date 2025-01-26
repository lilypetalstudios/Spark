import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

enum TaskDifficulty: String, CaseIterable, Identifiable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var id: String { self.rawValue }
    var points: Int {
        switch self {
        case .easy: return 5
        case .medium: return 10
        case .hard: return 20
        }
    }
}

struct Task: Identifiable {
    let id: UUID
    var title: String
    var deadline: Date
    var priority: Color
    var difficulty: TaskDifficulty
    var isCompleted: Bool
}

class TaskStore: ObservableObject {
    static let shared = TaskStore()
    @Published var tasks: [Task] = []
    @Published var totalPoints: Int = 0
    private var userId: String?
    private let db = Firestore.firestore()

    init() {
        userId = Auth.auth().currentUser?.uid
        loadTasks()
    }
    
    static func getUserPoints(completion: @escaping (Int) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(0)
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()?["totalPoints"] as? Int ?? 0
                completion(data)
            } else {
                completion(0)
            }
        }
    }

    func addTask(title: String, deadline: Date, priority: Color, difficulty: TaskDifficulty) {
        let newTask = Task(id: UUID(), title: title, deadline: deadline, priority: priority, difficulty: difficulty, isCompleted: false)
        tasks.append(newTask)
       
        saveTasks()
    }

    func editTask(task: Task, newTitle: String, newDeadline: Date, newPriority: Color, newDifficulty: TaskDifficulty) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = newTitle
            tasks[index].deadline = newDeadline
            tasks[index].priority = newPriority
            tasks[index].difficulty = newDifficulty
            saveTasks()
        }
    }

    func deleteTask(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
            saveTasks()
        }
    }

    func toggleCompletion(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            if tasks[index].isCompleted {
                totalPoints += tasks[index].difficulty.points
            } else {
                totalPoints -= tasks[index].difficulty.points
            }

            saveTasks()
        }
    }

    private func loadTasks() {
        guard let userId = userId else { return }

        let userRef = db.collection("users").document(userId)

        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()?["tasks"] as? [[String: Any]] ?? []
                self.tasks = data.compactMap { dict in
                    guard let id = dict["id"] as? String,
                          let title = dict["title"] as? String,
                          let deadline = (dict["deadline"] as? Timestamp)?.dateValue(),
                          let priority = dict["priority"] as? String,
                          let difficulty = dict["difficulty"] as? String,
                          let isCompleted = dict["isCompleted"] as? Bool else { return nil }
                    
                    return Task(id: UUID(uuidString: id) ?? UUID(), title: title, deadline: deadline, priority: Color(priority), difficulty: TaskDifficulty(rawValue: difficulty) ?? .easy, isCompleted: isCompleted)
                }
                self.updateTotalPoints()
            }
        }
    }

    private func saveTasks() {
        guard let userId = userId else { return }
        
        let userRef = db.collection("users").document(userId)
        
        let tasksData = tasks.map { task -> [String: Any] in
            return [
                "id": task.id.uuidString,
                "title": task.title,
                "deadline": Timestamp(date: task.deadline),
                "priority": "\(task.priority)",
                "difficulty": task.difficulty.rawValue,
                "isCompleted": task.isCompleted
            ]
        }

        userRef.setData([
            "tasks": tasksData,
            "totalPoints": totalPoints
        ], merge: true) { error in
            if let error = error {
                print("Error saving tasks: \(error.localizedDescription)")
            }
        }
    }

    private func updateTotalPoints() {
        totalPoints = tasks.filter { $0.isCompleted }.reduce(0) { $0 + $1.difficulty.points }
        saveTasks()
    }
}

struct TaskView: View {
    @StateObject private var taskStore = TaskStore()
    @State private var showingAddTask = false
    @State private var showingEditTask = false
    @State private var selectedTask: Task?

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("**your**")
                        .font(.largeTitle)
                        .foregroundColor(Color.black)

                    Text("**tasks**")
                        .font(.largeTitle)
                        .foregroundColor(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                }

                List {
                    ForEach(taskStore.tasks) { task in
                        HStack {
                            Button(action: {
                                taskStore.toggleCompletion(task: task)
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isCompleted ? .green : .gray)
                                    .font(.title)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text(task.title)
                                .strikethrough(task.isCompleted)
                                .foregroundColor(task.isCompleted ? .gray : .black)

                            Spacer()
                            
                            Text("\(task.difficulty.points) pts")
                            Image(systemName: "circle.fill")
                                .foregroundColor(task.priority)
                        }
                        .padding()
                        .background(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                        .cornerRadius(8)
                        .swipeActions {
                            Button {
                                selectedTask = task
                            } label: {
                                Label("edit", systemImage: "pencil")
                            }
                            .tint(.blue)

                            Button(role: .destructive) {
                                taskStore.deleteTask(task: task)
                            } label: {
                                Label("delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(PlainListStyle())

                HStack {
                    Text("**total points: \(taskStore.totalPoints)**")
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                showingAddTask.toggle()
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.black)
            })
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(taskStore: taskStore)
            }
            .sheet(item: $selectedTask) { task in
                EditTaskView(taskStore: taskStore, task: task)
            }
        }
        .tint(.black)
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { taskStore.tasks[$0] }.forEach(taskStore.deleteTask)
    }
}

struct AddTaskView: View {
    @ObservedObject var taskStore: TaskStore
    @State private var newTaskTitle: String = ""
    @State private var newTaskDeadline: Date = Date()
    @State private var selectedPriority: Color = .green
    @State private var selectedDifficulty: TaskDifficulty = .easy

    var body: some View {
        VStack {
            Text("**add new task**")
                .font(.largeTitle)
                .padding()

            TextField("**task title**", text: $newTaskTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            DatePicker("**deadline**", selection: $newTaskDeadline, displayedComponents: .date)
                .padding()

            Picker("priority", selection: $selectedPriority) {
                Text("green").tag(Color.green)
                Text("yellow").tag(Color.yellow)
                Text("red").tag(Color.red)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Picker("**difficulty**", selection: $selectedDifficulty) {
                ForEach(TaskDifficulty.allCases) { difficulty in
                    Text(difficulty.rawValue.capitalized).tag(difficulty)
                }
            }
            .padding()

            Button(action: {
                if !newTaskTitle.isEmpty {
                    taskStore.addTask(title: newTaskTitle, deadline: newTaskDeadline, priority: selectedPriority, difficulty: selectedDifficulty)
                    newTaskTitle = ""
                }
            }) {
                Text("add task")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding()
                    .cornerRadius(10)
                    .background(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
            }
            .padding()

            Spacer()
        }
    }
}

struct EditTaskView: View {
    @ObservedObject var taskStore: TaskStore
    var task: Task
    @State private var updatedTitle: String = ""
    @State private var updatedDeadline: Date = Date()
    @State private var updatedPriority: Color = .green
    @State private var updatedDifficulty: TaskDifficulty = .easy

    var body: some View {
        VStack {
            Text("**edit task**")
                .font(.largeTitle)
                .padding()

            TextField("**task title**", text: $updatedTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onAppear {
                    updatedTitle = task.title
                    updatedDeadline = task.deadline
                    updatedPriority = task.priority
                    updatedDifficulty = task.difficulty
                }

            DatePicker("**deadline**", selection: $updatedDeadline, displayedComponents: .date)
                .padding()

            Picker("priority", selection: $updatedPriority) {
                Text("green").tag(Color.green)
                Text("yellow").tag(Color.yellow)
                Text("red").tag(Color.red)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Picker("**difficulty**", selection: $updatedDifficulty) {
                ForEach(TaskDifficulty.allCases) { difficulty in
                    Text(difficulty.rawValue.capitalized).tag(difficulty)
                }
            }
            .padding()

            Button(action: {
                taskStore.editTask(task: task, newTitle: updatedTitle, newDeadline: updatedDeadline, newPriority: updatedPriority, newDifficulty: updatedDifficulty)
            }) {
                Text("save changes")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
    }
}

struct TaskView_Previews: PreviewProvider {
    static var previews: some View {
        TaskView()
    }
}
