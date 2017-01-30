# This class represents a Docker Task.
class Docker::Task
  include Docker::Base

  # Return all of the Tasks.
  def self.all(opts = {}, conn = Docker.connection)
    hashes = Docker::Util.parse_json(conn.get('/tasks', opts)) || []
    hashes.map { |hash| new(conn, hash) }
  end

  # Return the Task with specified ID.
  def self.get(id, opts = {}, conn = Docker.connection)
    task_json = conn.get("/tasks/#{URI.encode(id)}", opts)
    hash = Docker::Util.parse_json(task_json) || {}
    new(conn, hash)
  end

  private_class_method :new
end
