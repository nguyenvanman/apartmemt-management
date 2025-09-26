import { createClient } from "jsr:@supabase/supabase-js@2";
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  read,
  utils,
} from "https://cdn.sheetjs.com/xlsx-0.20.3/package/xlsx.mjs";

const TOTAL_REVENUE_FIELD = "Tổng doanh thu";
const FIXED_COST_FIELD = "Chi phí cố định";
const REVENUE_AFTER_FIXED_COST = "Doanh thu tính CP vận hành";
const OPERATING_COST = "Chi phí vận hành";
const INVESTOR_REVENUE = "Doanh thu của CĐT trong kỳ";
const ADVANCE_PAYMENT = "Chi hộ";
const INVESTOR_PROFIT = "Lợi nhuận của CĐT trong kỳ";
const INVESTOR_TOTAL_INCOME = "Tổng tiền về CĐT trong kỳ";

const extractApartmentRevenuesData = async (file: File) => {
  const arrayBuffer = await file.arrayBuffer();
  const workbook = read(arrayBuffer, { type: "array" });
  const firstSheetName = workbook.SheetNames[0];
  const data = utils.sheet_to_row_object_array(workbook.Sheets[firstSheetName]);

  const findValueByField = (fieldName) => {
    const found = data.find((r) => r.__EMPTY === fieldName);
    if (found) {
      return found.__EMPTY_1;
    }

    return 0;
  };

  const findDetailsItems = (startField, endField) => {
    const startIndex = data.findIndex((item) => item.__EMPTY === startField);
    const endIndex = data.findIndex((item) => item.__EMPTY === endField);

    if (startIndex === -1 || endIndex === -1 || endIndex <= startIndex + 1) {
      return [];
    }

    return data.slice(startIndex + 1, endIndex).map((i) => {
      return {
        description: i.__EMPTY,
        amount: i.__EMPTY_1,
        note: i.__EMPTY_2 ?? "",
      };
    });
  };

  return {
    totalRevenue: findValueByField(TOTAL_REVENUE_FIELD),
    fixedCost: findValueByField(FIXED_COST_FIELD),
    fixedCostDetails: findDetailsItems(
      FIXED_COST_FIELD,
      REVENUE_AFTER_FIXED_COST
    ),
    revenueAfterFixedCost: findValueByField(REVENUE_AFTER_FIXED_COST),
    operatingCost: findValueByField(OPERATING_COST),
    investorRevenue: findValueByField(INVESTOR_REVENUE),
    advancePayment: findValueByField(ADVANCE_PAYMENT),
    advancePaymentDetails: findDetailsItems(ADVANCE_PAYMENT, INVESTOR_PROFIT),
    investorProfit: findValueByField(INVESTOR_PROFIT),
    investorTotalIncome: findValueByField(INVESTOR_TOTAL_INCOME),
  };
};

const saveApartmentRevenuesData = async (
  supabase,
  {
    totalRevenue,
    fixedCost,
    fixedCostDetails,
    revenueAfterFixedCost,
    operatingCost,
    investorRevenue,
    advancePayment,
    advancePaymentDetails,
    investorProfit,
    investorTotalIncome,
  },
  apartmentId,
  month,
  year
) => {
  const { data: revenues, error: revenueError } = await supabase
    .from("apartment_revenues")
    .insert([
      {
        apartment_id: apartmentId,
        cycle_month: month,
        cycle_year: year,
        total_revenue: totalRevenue,
        fixed_cost: fixedCost,
        revenue_after_fixed_cost: revenueAfterFixedCost,
        operating_cost: operatingCost,
        investor_revenue: investorRevenue,
        advance_payment: advancePayment,
        investor_profit: investorProfit,
        investor_total_income: investorTotalIncome,
      },
    ])
    .select()
    .single();

  if (revenueError) {
    throw new Error(
      `Insert apartment_revenues failed: ${revenueError.message}`
    );
  }

  const revenueId = revenues.id;

  const details = [
    ...(fixedCostDetails || []).map((d) => ({
      description: d.description,
      amount: d.amount,
      note: d.note,
      type: "fixed_cost",
      apartment_revenue_id: revenueId,
    })),
    ...(advancePaymentDetails || []).map((d) => ({
      description: d.description,
      amount: d.amount,
      note: d.note,
      type: "advance_payment",
      apartment_revenue_id: revenueId,
    })),
  ];

  if (details.length > 0) {
    const { error: detailsError } = await supabase
      .from("apartment_revenue_details")
      .insert(details);

    if (detailsError) {
      throw new Error(
        `Insert apartment_revenue_details failed: ${detailsError.message}`
      );
    }
  }

  const { data: detailsData, error: fetchError } = await supabase
    .from("apartment_revenue_details")
    .select("*")
    .eq("apartment_revenue_id", revenueId);

  if (fetchError) {
    throw new Error(
      `Fetch apartment_revenue_details failed: ${fetchError.message}`
    );
  }

  return {
    ...revenues,
    revenue_details: detailsData ?? [],
  };
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const formData = await req.formData();
    const file = formData.get("file") as File;
    const apartmentId = formData.get("apartment_id");
    const month = parseInt(formData.get("month") as string, 10);
    const year = parseInt(formData.get("year") as string, 10);

    const data = await extractApartmentRevenuesData(file);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const saved = await saveApartmentRevenuesData(
      supabase,
      data,
      apartmentId,
      month,
      year
    );

    return new Response(JSON.stringify(saved), {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
        "Content-Type": "application/json",
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "Failed to upload report",
        details: error.message,
      }),
      {
        status: 500,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
          "Access-Control-Allow-Headers":
            "authorization, x-client-info, apikey, content-type",
          "Content-Type": "application/json",
        },
      }
    );
  }
});
