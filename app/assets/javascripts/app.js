
$(function () {

  $(document).on('click', 'a[data-confirm]', function (e) {
    var message = $(this).data('confirm');
    if (!confirm(message)) {
      e.preventDefault();
      e.stopped = true;
    }
  });

  $(document).on('click', 'a.popup', function (e) {
    window.open(this.href, null, 'scrollbars=yes,width=600,height=600,left=150,top=150').focus();
    return false;
  });

  $('textarea.wysiwyg').not('textarea.wysified').each(function () {
    var textarea = this;
    var summernote = $('<div class="summernote"></div>');
    $(summernote).insertAfter(this);
    $(summernote).summernote({
      toolbar: [
        ['view', ['codeview', 'fullscreen']],
        ['style', ['style']],
        ['font', ['bold', 'italic', 'underline', 'clear']],
        ['color', ['color']],
        ['para', ['ul', 'ol', 'paragraph']],
        ['height', ['height']],
        ['table', ['table']],
        ['insert', ['picture', 'link', 'video']],
      ],
      height: 200,
      codemirror: {
        theme: 'monokai'
      }
    });
    $('.note-image-input').parent().hide();
    $(textarea).prop('required', false);
    $(summernote).code($(textarea).val());
    $(textarea).addClass('wysified').hide();
    $(textarea.form).submit(function () {
      $(textarea).val($(summernote).code());
    });
  });

});