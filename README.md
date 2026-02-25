# Todo App - Flutter + Phoenix

A full-stack todo application with Flutter frontend and Elixir/Phoenix backend.

## Project Structure

```
my_todo/
├── backend/          # Phoenix API server
│   ├── lib/
│   │   ├── todo_backend/
│   │   │   ├── todo/           # Todo context and business logic
│   │   │   └── web/           # Web layer (controllers, views)
│   │   └── todo_backend.ex
│   ├── priv/
│   │   └── repo/
│   │       └── migrations/     # Database migrations
│   └── mix.exs
└── frontend/         # Flutter mobile app
    ├── lib/
    │   ├── models/
    │   │   └── todo.dart      # Todo data model
    │   ├── services/
    │   │   └── api_service.dart # HTTP API client
    │   ├── screens/
    │   │   ├── todo_list_screen.dart
    │   │   └── add_todo_screen.dart
    │   └── main.dart
    └── pubspec.yaml
```

## Backend (Phoenix)

### API Endpoints

- `GET /api/items` - List all todos
- `POST /api/items` - Create a new todo
- `PUT /api/items/:id` - Update a todo
- `DELETE /api/items/:id` - Delete a todo

### Data Model

```elixir
%TodoBackend.Todo.Item{
  id: integer,
  title: string,
  description: string,
  completed: boolean,
  inserted_at: datetime,
  updated_at: datetime
}
```

### Running the Backend

```bash
cd backend
mix deps.get
mix ecto.migrate
mix phx.server
```

The server will start at `http://localhost:4000`

## Frontend (Flutter)

### Key Components

#### Todo Model (`lib/models/todo.dart`)
- Represents a todo item with JSON serialization
- Handles data validation and conversion

#### API Service (`lib/services/api_service.dart`)
- HTTP client for communicating with Phoenix backend
- Handles all CRUD operations
- Manages error handling and response parsing

#### Screens
- `TodoListScreen`: Main screen showing list of todos
- `AddTodoScreen`: Form for creating new todos

### Running the Frontend

```bash
cd frontend
flutter pub get
flutter run
```

## How Frontend-Backend Communication Works

### 1. HTTP Communication
The Flutter app uses the `http` package to make REST API calls to the Phoenix backend:

```dart
// Example: Fetching all todos
final response = await http.get(
  Uri.parse('$baseUrl/items'),
  headers: {'Accept': 'application/json'},
);
```

### 2. Data Flow

**Fetching Todos:**
1. Flutter app calls `ApiService.getTodos()`
2. HTTP GET request sent to `http://localhost:4000/api/items`
3. Phoenix controller queries database and returns JSON
4. Flutter parses JSON and converts to Todo objects
5. UI updates with the list of todos

**Creating a Todo:**
1. User fills form in Flutter app
2. Flutter calls `ApiService.createTodo(todo)`
3. HTTP POST request with JSON data sent to Phoenix
4. Phoenix validates data and saves to database
5. Phoenix returns created todo as JSON
6. Flutter updates local state and refreshes list

### 3. JSON Format

**Request (Create Todo):**
```json
{
  "item": {
    "title": "New Todo",
    "description": "Description here",
    "completed": false
  }
}
```

**Response (Single Todo):**
```json
{
  "data": {
    "id": 1,
    "title": "New Todo",
    "description": "Description here",
    "completed": false
  }
}
```

**Response (List of Todos):**
```json
{
  "data": [
    {
      "id": 1,
      "title": "First Todo",
      "description": "My first todo",
      "completed": false
    },
    {
      "id": 2,
      "title": "Second Todo",
      "description": "Another todo",
      "completed": true
    }
  ]
}
```

## Features

- ✅ View all todos
- ✅ Add new todos
- ✅ Mark todos as complete/incomplete
- ✅ Delete todos
- ✅ Real-time updates
- ✅ Error handling
- ✅ Loading states
- ✅ Empty state handling

## Development Notes

### Backend (Phoenix)
- Uses Ecto for database operations
- JSON API with proper error handling
- CORS enabled for Flutter development
- PostgreSQL database

### Frontend (Flutter)
- Material Design 3 UI
- State management with StatefulWidget
- Async/await for API calls
- Proper error handling and user feedback
- Form validation

## Testing

### Backend Tests
```bash
cd backend
mix test
```

### Frontend Tests
```bash
cd frontend
flutter test
```

## Future Enhancements

- [ ] Add user authentication
- [ ] Implement real-time updates with Phoenix Channels
- [ ] Add due dates and priorities
- [ ] Implement search and filtering
- [ ] Add categories/tags
- [ ] Offline support with local storage
- [ ] Push notifications
