@SignUpModal = React.createClass
  getInitialState: ->
    authenticity_token: @props.authenticity_token

  render: ->
    React.DOM.div
      className: 'row'
      React.DOM.div
        className: "small-6 small-offset-3 columns"
        React.createElement AlertBox, id: "signUpBox"
        React.createElement SignUpForm, authenticity_token: @state.authenticity_token
