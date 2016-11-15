@SignUpModal = React.createClass
  getInitialState: ->
    authenticity_token: @props.authenticity_token

  render: ->
    React.DOM.div
      className: 'row row-custom'
      React.DOM.div
        className: "register-form"
        React.createElement AlertBox, id: "signUpBox"
        React.createElement SignUpForm, authenticity_token: @state.authenticity_token
