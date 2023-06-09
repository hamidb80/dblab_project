const
  TPilot* = "خلبان"
  TCost* = "مبلغ"
  TOrigin* = "مبدا"
  TDest* = "مقصد"
  TSeatNumber* = "شماره صندلی"
  TBuy* = "خرید"
  TCompany* = "شرکت"
  TInternationalCode* = "کد ملی"
  Tfly* = "پرواز"
  TDate* = "تاریخ"
  Tid* = "شناسه"
  Ttime* = "زمان"
  TCapacity* = "ظرفیت"
  TPassenger* = "مسافر"
  TisCancelled* = "لغو شده؟"
  Tyes* = "بله"
  Tno* = "خیر"


func toFa*(b: bool): string = 
  case b
  of true: Tyes
  of false: Tno