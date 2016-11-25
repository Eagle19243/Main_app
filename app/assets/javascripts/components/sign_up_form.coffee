@SignUpForm = React.createClass
  getInitialState: ->
    name: ''
    new_email: ''
    new_password: ''
    password_confirmation: ''
    authenticity_token: @props.authenticity_token

  handleSubmit: (e) ->
    e.preventDefault()
    $.ajax
      method: 'POST'
      url: '/users'
      data: {
        utf8: "✓",
        authenticity_token: @state.authenticity_token,
        user: {
          name: @state.name
          email: @state.new_email,
          password: @state.new_password,
          password_confirmation: @state.password_confirmation
        },
        commit: "Sign up"
      }
      dataType: 'JSON'
      success: (response) =>
        window.location.replace '/home'
      error: (response) =>
        @performNotSuccessResult response

  performNotSuccessResult: (response) ->
    errors = response.responseJSON.errors
    message = ""
    for error, value of errors
      message_node = error.charAt(0).toUpperCase() + error.slice(1) + " " + value + "<br />"
      message += message_node.replace "_", " "
    $('#signUpBox').html(message)
    $('#signUpBox').parent().show()

  inputChanged: (e) ->
    name = e.target.name
    @setState "#{ name }": e.target.value

  render: ->
   React.DOM.div
      className: "abc"
      React.DOM.form
        role: "form"
        className: "new_user"
        onSubmit: @handleSubmit
#       React.DOM.h3 null, "Sign up"
        React.DOM.div
          className: 'form-group'
          React.DOM.label null,'Name'
          React.DOM.input
            type: 'text'
            name: 'name'
            value: @state.name
            onChange: @inputChanged
        React.DOM.div
          className: 'form-group'
          React.DOM.label null,'Email'
          React.DOM.input
            type: 'email'
            name: 'new_email'
            value: @state.new_email
            onChange: @inputChanged
        React.DOM.div
          className: 'form-group'
          React.DOM.label null, 'Password'
          React.DOM.input
            type: 'password'
            name: 'new_password'
            value: @state.new_password
            onChange: @inputChanged
        React.DOM.div
          className: 'form-group'
          React.DOM.label null, 'Repeat Password'
          React.DOM.input
            type: 'password'
            name: 'password_confirmation'
            value: @state.password_confirmation
            onChange: @inputChanged
        React.DOM.button
          className: "btn btn-primary normal-button"
          type: 'submit'
          name: 'commit'
          'Sign up'

