require "pg"

class DatabasePersistence
  
  def initialize(logger)
    @db = PG.connect(dbname: 'todo_lists')
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: + #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)
    tuple = result.first
    {id: tuple['id'], name: tuple['name'], todos: list_todos(tuple['id'])}
  end

  def all_lists
    # @session[:lists]
    sql = "SELECT * FROM lists"
    result = query(sql)
    result.map do |tuple|
      todos = list_todos(tuple['id'])
      {id: tuple['id'], name: tuple['name'], todos: todos}
    end
  end

  def list_todos(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, list_id)
    result.map do |tuple|
      {id: tuple['id'], name: tuple['name'], completed: tuple['completed'] == 't'}
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end

  def delete_list(id)
    sql = "DELETE FROM lists WHERE id = $1"
    query(sql, id)
  end

  def update_list(list_name, id)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql, list_name, id)
  end

  def add_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2)"
    query(sql, todo_name, list_id)
  end

  def delete_todo_from_list(todo_id)
    sql = "DELETE FROM todos WHERE id = $1"
    query(sql, todo_id)
  end

  def update_todo(todo_id, is_completed)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2"
    query(sql, is_completed, todo_id)
  end

  def mark_all_complete(list_id)
    sql = "UPDATE todos SET completed = $1 WHERE list_id = $2"
    query(sql, true, list_id)
  end

end