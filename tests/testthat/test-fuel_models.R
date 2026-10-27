box::use(
  testthat[describe, expect_equal, expect_false, expect_null, expect_true, it],
)

box::use(
  app/logic/fuel_models,
)

tl2 <- fuel_models$fuel_model_lookup("TL2", "FBFM40") # 0.2 ft deep
gr2 <- fuel_models$fuel_model_lookup("GR2", "FBFM40")
model_loads <- function(fm) fuel_models$fuel_model_bed(fm)$load_tonsac

describe("depth_scaled_loads", {
  it("returns the model's own loads at the model's depth", {
    expect_equal(fuel_models$depth_scaled_loads(tl2, 0.2 * 30.48), model_loads(tl2))
  })

  it("scales every load class with depth, keeping the model's bulk density", {
    loads <- fuel_models$depth_scaled_loads(tl2, 2 * 0.2 * 30.48)
    expect_equal(loads, 2 * model_loads(tl2))
    expect_equal(names(loads), c("d1", "d10", "d100", "herb", "woody"))
  })

  it("returns NULL without a usable depth or model", {
    expect_null(fuel_models$depth_scaled_loads(tl2, NA))
    expect_null(fuel_models$depth_scaled_loads(tl2, NULL))
    expect_null(fuel_models$depth_scaled_loads(tl2, -1))
    expect_null(fuel_models$depth_scaled_loads(NULL, 5))
  })

  it("returns NULL for a non-burnable model, which has no fuel bed", {
    expect_null(fuel_models$depth_scaled_loads(fuel_models$fuel_model_lookup(98), 5))
  })
})

describe("is_litter_model", {
  it("is TRUE for timber litter models in both systems", {
    expect_true(fuel_models$is_litter_model(tl2))
    expect_true(fuel_models$is_litter_model(fuel_models$fuel_model_lookup(9, "FBFM13")))
  })

  it("is FALSE for other models and for no model", {
    expect_false(fuel_models$is_litter_model(gr2))
    expect_false(fuel_models$is_litter_model(NULL))
  })
})
