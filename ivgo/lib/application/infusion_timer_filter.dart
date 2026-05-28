import 'package:ivgo/application/infusion_timer_status_filter.dart';

class InfusionTimerFilter {
 final InfusionTimerStatusFilter statusFilter;
 final String textFilter;

 bool get isActive => isStatusActive || isTextActive;
 bool get isStatusActive => statusFilter != InfusionTimerStatusFilter.all;
 bool get isTextActive => textFilter.isNotEmpty;

 const InfusionTimerFilter({this.statusFilter = InfusionTimerStatusFilter.all, this.textFilter = ''});
}