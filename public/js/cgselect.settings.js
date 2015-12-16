window.onload=function(){
    $('.selectpicker').selectpicker();
};
function validate_input(){
    if($(".selectpicker").val()=="0000") {
        alert("请选择地市！");
        return false;
    }
    if($("#dept").val()=="" && $("#pname").val()==""){
        alert("单位名和人名至少要填一项！");
        return false;
    }
    return true;
}
