# This class represents a Docker Service.
class Docker::Service
  include Docker::Base

  # Return all of the Services.
  def self.all(opts = {}, conn = Docker.connection)
    hashes = Docker::Util.parse_json(conn.get('/services', opts)) || []
    hashes.map { |hash| new(conn, hash) }
  end

  # Return the Service with specified ID.
  def self.get(id, opts = {}, conn = Docker.connection)
    service_json = conn.get("/services/#{URI.encode(id)}", opts)
    hash = Docker::Util.parse_json(service_json) || {}
    new(conn, hash)
  end

  # Create a new Service.
  def self.create(opts = {}, conn = Docker.connection)
    resp = conn.post('/services/create', {}, :body => opts.to_json)
    hash = Docker::Util.parse_json(resp) || {}
    new(conn, hash)
  end

  # Update the Service.
  def update(query, opts)
    connection.post(path_for(:update), query, body: opts.to_json)
  end

  # Remove the Service.
  def remove(options = {})
    connection.delete("/services/#{self.id}", options)
    nil
  end
  alias_method :delete, :remove

  def logs(opts = {})
    connection.get(path_for(:logs), opts)
  end

  def streaming_logs(opts = {}, &block)
    stack_size = opts.delete('stack_size') || -1
    tty = opts.delete('tty') || opts.delete(:tty) || false
    msgs = Docker::MessagesStack.new(stack_size)
    excon_params = {response_block: Docker::Util.attach_for(block, msgs, tty)}

    connection.get(path_for(:logs), opts, excon_params)
    msgs.messages.join
  end

  # Convenience method to return the path for a particular resource.
  def path_for(resource)
    "/services/#{self.id}/#{resource}"
  end

  private :path_for
  private_class_method :new
end
