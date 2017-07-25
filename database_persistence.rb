require "pg"

class DatabasePersistence
  
  def initialize
    @db = PG.connect(dbname: 'todo_lists')
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = @db.exec_params(sql, [id])
    tuple = result.first
    {id: tuple['id'], name: tuple['name'], todos: []}
  end

  def all_lists
    # @session[:lists]
    sql = "SELECT * FROM lists"
    result = @db.exec(sql)
    result.map do |tuple|
      {id: tuple['id'], name: tuple['name'], todos: []}
    end
  end

  def create_new_list(list_name)
    id = next_element_id(all_lists)
    @session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    @session[:lists].reject! { |list| list[:id] == id }
  end

  def update_list(list_name, id)
    list = find_list(id)
    list[:name] = list_name
  end

  def add_new_todo(list_id, todo_name)
    list = find_list(list_id)
    todo_id = next_element_id(list[:todos])
    list[:todos] << { id: todo_id, name: todo_name, completed: false }
  end

  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def update_todo(list_id, todo_id, is_completed)
    list = find_list(list_id)
    todo = list[:todos].find { |todo| todo[:id] == todo_id }
    todo[:completed] = is_completed
  end

  def mark_all_complete(list_id)
    list = find_list(list_id)
    
    list[:todos].each do |todo|
      todo[:completed] = true
    end
  end

end