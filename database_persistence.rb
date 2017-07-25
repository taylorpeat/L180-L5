require "pg"

class DatabasePersistence
  
  def initialize(logger)
    @db = if Sinatra::Base.production?
        PG.connect(ENV['DATABASE_URL'])
      else
        PG.connect(dbname: "todo_lists")
      end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: + #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = <<~SQL
      SELECT
        l.id,
        l.name,
        COUNT(NULLIF(t.completed, true)) AS todos_remaining_count,
        COUNT(t.id) AS todos_count
        FROM lists l
        LEFT JOIN todos t ON l.id = t.list_id
        WHERE l.id = $1
        GROUP BY l.id
        ORDER BY l.name;
    SQL
    result = query(sql, id)
    tuple_to_list_hash(result.first)
  end

  def all_lists
    # @session[:lists]
    sql = <<~SQL
      SELECT
        l.id,
        l.name,
        COUNT(NULLIF(t.completed, true)) AS todos_remaining_count,
        COUNT(t.id) AS todos_count
        FROM lists l
        LEFT JOIN todos t ON l.id = t.list_id
        GROUP BY l.id
        ORDER BY l.name;
    SQL
    result = query(sql)
    result.map do |tuple|
      tuple_to_list_hash(tuple)
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

  def list_todos(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, list_id)
    result.map do |tuple|
      {id: tuple['id'], name: tuple['name'], completed: tuple['completed'] == 't'}
    end
  end

  private

  def tuple_to_list_hash(tuple)
    {
      id: tuple['id'],
      name: tuple['name'],
      todos_remaining_count: tuple['todos_remaining_count'].to_i,
      todos_count: tuple['todos_count'].to_i,
    }
  end

end