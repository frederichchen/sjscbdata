$.extend($.fn.pickadate.defaults, {
    monthsFull: ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'],
    weekdaysShort: ['周日', '周一', '周二', '周三', '周四', '周五', '周六'],
    today: '今天',
    clear: '清除',
    close: '关闭',
    format: 'yyyy-mm-dd',
    formatSubmit: 'yyyy-mm-dd'
})
$('.datepicker').pickadate()
function validate_input(){
    var now=new Date();
    if($("#startdate").val()=="") {
        alert("请输入开始日期");
        return false;
    }
    if(Date.parse($("#startdate").val())>now) {
        alert("开始日期不能在今天之后！");
        return false;
    }
    return true;
}
