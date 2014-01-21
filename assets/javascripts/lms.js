$(document).ready(function(){
	$('table tr.odd, table tr.even').click(function(){
		$('table tr.odd.selected-row, table tr.even.selected-row').removeClass('selected-row');
		$(this).addClass('selected-row');
        });
	
	$('#lms_leave_setting_will_be_carry_forwarded_true').click(function(){
		$(this).parents('.field_wrapper').children('.sub_field_wrapper').show();
		$('#lms_leave_setting_max_days').removeAttr('disabled');
	});

	$('#lms_leave_setting_will_be_carry_forwarded_false').click(function(){
		$(this).parents('.field_wrapper').children('.sub_field_wrapper').hide();
		$('#lms_leave_setting_max_days').attr('disabled', 'disabled');
	});

	$('#lms_leave_setting_work_from_home_true').click(function(){
		$(this).parents('.field_wrapper').children('.sub_field_wrapper').show();
		$('#lms_leave_setting_work_from_home_limit').removeAttr('disabled');
	});

	$('#lms_leave_setting_work_from_home_false').click(function(){
		$(this).parents('.field_wrapper').children('.sub_field_wrapper').hide();
		$('#lms_leave_setting_work_from_home_limit').attr('disabled', 'disabled');
	});
	
});

function zeroPad(num, places){
	size = num.toString().length;
	placesToFill = places - size;
	if(placesToFill > 0){
		zeroPads = new Array();
		while(zeroPads.length < placesToFill){
			zeroPads.push(0);
		}
		num = zeroPads.join('') + num.toString();
	}
	return num;
}


//////////////////////////// Dates functions //////////////////////////////////////
var dayNames = new Array('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
var cYFDate = new Date(new Date().getFullYear() + "-01-01");
var cYLDate = new Date(new Date().getFullYear() + "-12-31");

function convertAllToDate(datesString){
	dates = new Array();
	for(i=0;i<datesString.length;i++){
		dates.push(new Date(datesString[i]));
	}
	return dates;
}

function translateAllToString(dateObjs, format, seperator){
	if(dateObjs.length == 0){return [];}
	else{
		dates = new Array();
		for(i=0; i< dateObjs.length; i++){
			dates.push(translate_to_string(dateObjs[i], format, seperator));
		}
		return dates;
	}
}

function translate_to_string(dateObj, format, seperator){
	dateObj = dateObj || new Date();
	format = format || 'YMD';
	seperator = seperator || '-';
	year = dateObj.getFullYear();
	month = zeroPad(dateObj.getMonth() + 1, 2);
	date = zeroPad(dateObj.getDate(), 2);
	switch(format){
		case 'YMD':
			return [year, month, date].join(seperator);
		case 'DMY':
			return [date, month, year].join(seperator);
		default:
			return [year, month, date].join(seperator);
	}
}

function dates_array(from_date, to_date){
	var dates = new Array();
	dates.push(from_date);
	day = 86400000;
	temp = from_date.getTime();
	while(temp < to_date.getTime()){
		temp += day;
		date = new Date(temp);
		if(!isWeekend(date.getDay()) && !isPublicHoliday(date)){
			dates.push(date);
		}
	}
	return dates;
}

function isWeekend(day){
	if(weekends.length == 0){return false;}
	else{
		weekendsArray = weekends.split(',');
		for(i=0; i< weekendsArray.length; i++){if(weekendsArray[i] == day){return true;}}
	}
}

function isPublicHoliday(date){
	if(public_holidays.length == 0){return false;}
	else{
		for(i=0; i< public_holidays.length; i++){if(public_holidays[i].toLocaleDateString() == date.toLocaleDateString()){return true;}}
	}
}
////////////////////////////////////////// Dates functions /////////////////////////////////////////////


///////////////////////////////////// apply leave ///////////////////////////////////////////////////////
function getDisableDates(){
	disable_dates = translateAllToString(public_holidays, 'DMY', ' ');
	disable_dates.push(['* * * ' + (weekends.length == 0 ? '-' : weekends), '18 12 2013'][0]);
	return disable_dates;
}

function swap_no_of_days(selector1, selector2){
	e1 = $('#' + selector1);
	e2 = $('#' + selector2);
	e1.attr('disabled', true);
	e1.parent().css('display', 'none');
	e2.attr('disabled', false);
	e2.parent().css('display', 'block');
}

function remove_date(closeButton){
	date = $(closeButton).siblings('#app-date').text();
	day_to_deduct = / :H$/.test(date) ? 0.5 : 1;
	no_of_days = parseFloat($('#lms_leave_no_of_days').val()) - day_to_deduct;
	$('#lms_leave_leave_dates_object [value="' + date + '"]').remove();
	$(closeButton).parent().remove();
	if(no_of_days == 0){
		$('#lms_leave_from_date, #lms_leave_to_date').val('');
	}
	else{
		$('#lms_leave_from_date').val($('#lms_leave_leave_dates_object').val()[0].split(' :')[0]);
		$('#lms_leave_to_date').val($('#lms_leave_leave_dates_object').val()[$('#lms_leave_leave_dates_object').val().length - 1].split(' :')[0]);
	}
	$('#lms_leave_no_of_days').val(no_of_days);
}

function half_day(hDButton){
	fDButton = $(hDButton).prev(); 
	date_obj = $(hDButton).parent().prev();
	date_option = $('#lms_leave_leave_dates_object [value="' + date_obj.text() + '"]');
	replace_txt = date_obj.text().replace(/ :F$/, " :H");
	no_of_days = parseFloat($('#lms_leave_no_of_days').val()) - 0.5;
	date_obj.text(replace_txt);
	$(hDButton).removeAttr('onclick');
	$(hDButton).addClass('active');
	fDButton.removeClass('active');
	fDButton.attr("onclick", "full_day(this);")
	$('#lms_leave_no_of_days').val(no_of_days);
	date_option.val(replace_txt);
	date_option.text(replace_txt);
}

function full_day(fDButton){
	hDButton = $(fDButton).next(); 
	date_obj = $(fDButton).parent().prev();
	date_option = $('#lms_leave_leave_dates_object [value="' + date_obj.text() + '"]');
	replace_txt = date_obj.text().replace(/ :H$/, " :F");
	no_of_days = parseFloat($('#lms_leave_no_of_days').val()) + 0.5;
	date_obj.text(replace_txt);
	$(fDButton).removeAttr('onclick');
	$(fDButton).addClass('active');
	hDButton.removeClass('active');
	hDButton.attr("onclick", "half_day(this);")
	$('#lms_leave_no_of_days').val(no_of_days);
	date_option.val(replace_txt);
	date_option.text(replace_txt);
}

function getDayName(ds){
	return dayNames[new Date(ds.split(/ :/)[0]).getDay()];
}

function clear_dates_fields(){
	$('#lms_leave_no_of_days').val(0);
	$('#leave_days').html('');
	$('#lms_leave_leave_dates_object').html('');
}
//////////////////////////////////// apply leave ////////////////////////////////////////////////////////


///////////////////////////////////// leave accounts management /////////////////////////////
function load_form(aId){
	var openAcc = $('.data-form');
	if(openAcc.length > 0){
		clear_form($(openAcc).attr('data-record'));
	}
	var account = $("#record-" + aId);
	var fields = $(account).children('.data-field');
	clear_error();
	var buttons = $(account).children('.form-buttons');
	$(fields).each(function(index, field){
		$(field).html("<input type=text name=" + formName + "[" + $(field).attr('data-column') + "]" +" value=" + $(field).text() + " >");
	});
	$(buttons).html("<input type=button name=Save value=Save onclick=submit_form(" + aId + ") >");
	$(buttons).append("<input type=button name=Cancel value=Cancel onclick=clear_form(" + aId + ") >");
	$(account).addClass('data-form');
}
  
function submit_form(aId){
	$.ajax({
		url: updateURL + aId,
		type: 'put',
		data : $("form[name=" + formName + "]").serialize(),
		dataType: 'json',
		success: function(response){
			if(response.status == 200){
				clear_form(aId, 'save', response.data);
			}
			else{
				show_error(aId, response.error);
			}
		}
	});
}
  
function clear_form(aId, button, record){
	var account = $("#record-" + aId);
	button = button || 'cancel';
	var fields = $(account).children('.data-field');
	var buttons = $(account).children('.form-buttons');
	clear_error();
	if(button == 'save'){
		$(fields).each(function(index, field){
			$(field).attr('data-value', parseFloat(record[$(field).attr('data-column')]));
			$(field).html($(field).attr('data-value'));
		});
	}
	else{
		$(fields).each(function(index, field){
			$(field).html($(field).attr('data-value'));
		});
	}
	$(buttons).html("<input type=button name=Edit value=Edit onclick=load_form(" + aId + ") >");
	$(account).removeClass('data-form');
}

function show_error(aId, error){
	var account = $("#record-" + aId);
	errors = "";
	$(error).each(function(i,e){errors += e + "<br>"});
	clear_error();
	$(account).before("<tr id=" + formName + "-error><td colspan=" + $(account).children().length + "><div id=errorExplanation style=margin-bottom:0px;>" + errors + "</div></td></tr>");
}
  
function clear_error(){
	$("#" + formName + "-error").remove();
}
////////////////////////////////////////// leave accounts management /////////////////////////////////////////////////
 