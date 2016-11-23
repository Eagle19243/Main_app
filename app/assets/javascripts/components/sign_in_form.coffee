@SignInForm = React.createClass
  getInitialState: ->
    email: ''
    password: ''
    remember_me: 0
    authenticity_token: @props.authenticity_token

  handleSubmit: (e) ->
    e.preventDefault()
    $.ajax
      method: 'POST'
      url: '/users/sign_in'
      data: {
              utf8: "✓",
              authenticity_token: @state.authenticity_token,
              user: {
                      email: @state.email,
                      password: @state.password,
                      remember_me: @state.remember_me
              },
              commit: "Sign in"
            }
      dataType: 'JSON'
      success: () =>
        window.location.replace window.location.origin + '/home'
      error: (response) =>
        @performNotSuccessResult response

  inputChanged: (e) ->
    name = e.target.name
    @setState "#{ name }": e.target.value

  checkboxChanged: (e) ->
    name = e.target.name
    @setState "#{ name }": 1^@state.remember_me

  performNotSuccessResult: (response) ->
    error = response.responseJSON.error
    $('#signInBox').text(error)
    $('#signInBox').parent().show()

  render: ->
    React.DOM.div
      className: "abc"
      React.DOM.form
        role: "form"
        onSubmit: @handleSubmit
#      React.DOM.h3 null, "Sign in"
        React.DOM.div
          className: 'form-group'
          React.DOM.label null,'Email'
          React.DOM.input
            type: 'email'
            name: 'email'
            value: @state.email
            onChange: @inputChanged
        React.DOM.div
          className: 'form-group'
          React.DOM.label null, 'Password'
          React.DOM.input
            type: 'password'
            name: 'password'
            value: @state.password
            onChange: @inputChanged
          React.DOM.div
            className: 'forgot-link'
            React.DOM.a
              className: ''
              href: '/users/password/new'
              'Forgot password?'

        React.DOM.div
          className: "checkbox"
          React.DOM.label null,
            React.DOM.input
              type: 'checkbox'
              name: 'remember_me'
              value: @state.remember_me
              onChange: @checkboxChanged
            " Remember me"
        React.DOM.button
          className: "btn btn-primary normal-button"
          type: 'submit'
          name: 'commit'
          'Sign in'

