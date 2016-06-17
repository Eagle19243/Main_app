var data = [
  { id: '1', title: 'Description', content: 'Content of the first tab.' },
  { id: '2', title: 'Tasks', content: 'Content of the second tab.' },
  { id: '3', title: 'News Feed', content: 'Content of the third tab.' },
  { id: '4', title: 'Publish', content: DescriptionContent }
]

var DescriptionContent = React.createClass({
  render: function () {
    return (<div>"Content of the first tab."</div>)
  }
})


/* Tabs Component Base using Foundation */

var Tabs = React.createClass({
  getInitialState: function () {
    return {activeTab: 0}
  },
  handleClick: function(index) {
    this.setState({activeTab: index})
    return false
  },
  render: function () {
    return (
      <div className="top-margin">
        <dl className="tabs tabs-override-margin-4rem-left">
          {this.props.data.map(function (tab, index) {
            var activeClass = this.state.activeTab === index ? 'active' : ''
            return (
              <dd className={'tab ' + activeClass} key={tab.id} id={tab.id} >
                <a href={'#Tab' + tab.id} onClick={this.handleClick.bind(this, index)}>{tab.title}</a>
              </dd>
            )
          }, this)}
        </dl>
        <div className="tabs-content">
          {this.props.data.map(function (tab, index) {
            var activeClass = this.state.activeTab === index ? 'active' : ''
            return (
              <div className={'content ' + activeClass} key={tab.id} >
                <p>{tab.content}</p>
              </div>
            )
          }, this)}
        </div>
      </div>
    )
  }
})

/*  Main Entry Point of the React Component. */

var ProjectData = React.createClass({
  render: function () {
      return (
        <Tabs data={data} />
      )
  }
})
