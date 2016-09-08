function rejectDiscussion(id) {
    $.ajax({
        url: '/discussions/'+id,
        type: 'DELETE',
        success: function(data) {
            $('#discussion-'+id).remove();
        },
        contentType: false,
        dataType: 'json'
    });
}

function acceptDiscussion(id) {
    $.ajax({
        url: '/discussions/'+id+'/accept',
        type: 'GET',
        success: function(data) {
            $('.'+data['field_name']+'-content').html(data['content']);
            $('#discussion-'+id).remove();
        },
        contentType: false,
        dataType: 'json'
    });
}