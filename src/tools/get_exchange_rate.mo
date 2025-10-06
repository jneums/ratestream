import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Json "mo:json";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Error "mo:base/Error";
import Text "mo:base/Text";

import ToolContext "ToolContext";

// Exchange Rate Canister Types
module {
  public type Asset = { class_ : AssetClass; symbol : Text };
  public type AssetClass = { #Cryptocurrency; #FiatCurrency };
  public type ExchangeRate = {
    metadata : ExchangeRateMetadata;
    rate : Nat64;
    timestamp : Nat64;
    quote_asset : Asset;
    base_asset : Asset;
  };
  public type ExchangeRateError = {
    #AnonymousPrincipalNotAllowed;
    #CryptoQuoteAssetNotFound;
    #FailedToAcceptCycles;
    #ForexBaseAssetNotFound;
    #CryptoBaseAssetNotFound;
    #StablecoinRateTooFewRates;
    #ForexAssetsNotFound;
    #InconsistentRatesReceived;
    #RateLimited;
    #StablecoinRateZeroRate;
    #Other : { code : Nat32; description : Text };
    #ForexInvalidTimestamp;
    #NotEnoughCycles;
    #ForexQuoteAssetNotFound;
    #StablecoinRateNotFound;
    #Pending;
  };
  public type ExchangeRateMetadata = {
    decimals : Nat32;
    forex_timestamp : ?Nat64;
    quote_asset_num_received_rates : Nat64;
    base_asset_num_received_rates : Nat64;
    base_asset_num_queried_sources : Nat64;
    standard_deviation : Nat64;
    quote_asset_num_queried_sources : Nat64;
  };
  public type GetExchangeRateRequest = {
    timestamp : ?Nat64;
    quote_asset : Asset;
    base_asset : Asset;
  };
  public type GetExchangeRateResult = {
    #Ok : ExchangeRate;
    #Err : ExchangeRateError;
  };
  public type Self = actor {
    get_exchange_rate : shared GetExchangeRateRequest -> async GetExchangeRateResult;
  };

  // Tool schema
  public func config() : McpTypes.Tool = {
    name = "get_exchange_rate";
    title = ?"Get Exchange Rate";
    description = ?(
      "Fetches the current exchange rate between two assets (cryptocurrencies or fiat currencies) " #
      "from the Internet Computer's Exchange Rate Canister. Returns the rate, timestamp, and metadata " #
      "about data sources and reliability."
    );
    payment = null;
    inputSchema = Json.obj([
      ("type", Json.str("object")),
      (
        "properties",
        Json.obj([
          (
            "base_asset_symbol",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Symbol of the base asset (e.g., 'ICP', 'BTC', 'USD').")),
              ("pattern", Json.str("^[A-Z]{3,10}$")),
            ]),
          ),
          (
            "base_asset_class",
            Json.obj([
              ("type", Json.str("string")),
              ("enum", Json.arr([Json.str("Cryptocurrency"), Json.str("FiatCurrency")])),
              ("description", Json.str("Asset class of the base asset.")),
            ]),
          ),
          (
            "quote_asset_symbol",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Symbol of the quote asset (e.g., 'USD', 'EUR', 'ICP').")),
              ("pattern", Json.str("^[A-Z]{3,10}$")),
            ]),
          ),
          (
            "quote_asset_class",
            Json.obj([
              ("type", Json.str("string")),
              ("enum", Json.arr([Json.str("Cryptocurrency"), Json.str("FiatCurrency")])),
              ("description", Json.str("Asset class of the quote asset.")),
            ]),
          ),
          (
            "timestamp",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Optional timestamp (in nanoseconds since UNIX epoch) for historical rates. Leave empty for current rate.")),
              ("pattern", Json.str("^[0-9]*$")),
            ]),
          ),
        ]),
      ),
      ("required", Json.arr([Json.str("base_asset_symbol"), Json.str("base_asset_class"), Json.str("quote_asset_symbol"), Json.str("quote_asset_class")])),
    ]);
    outputSchema = ?Json.obj([
      ("type", Json.str("object")),
      (
        "properties",
        Json.obj([
          (
            "rate",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("The exchange rate (quote asset per base asset).")),
            ]),
          ),
          (
            "timestamp",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Timestamp of the rate in nanoseconds since UNIX epoch.")),
            ]),
          ),
          (
            "base_asset",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("The base asset symbol and class.")),
            ]),
          ),
          (
            "quote_asset",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("The quote asset symbol and class.")),
            ]),
          ),
          (
            "decimals",
            Json.obj([
              ("type", Json.str("number")),
              ("description", Json.str("Number of decimal places in the rate.")),
            ]),
          ),
          (
            "base_asset_num_queried_sources",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Number of data sources queried for the base asset.")),
            ]),
          ),
          (
            "base_asset_num_received_rates",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Number of rates received for the base asset.")),
            ]),
          ),
          (
            "quote_asset_num_queried_sources",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Number of data sources queried for the quote asset.")),
            ]),
          ),
          (
            "quote_asset_num_received_rates",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Number of rates received for the quote asset.")),
            ]),
          ),
          (
            "standard_deviation",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Standard deviation of the collected rates.")),
            ]),
          ),
          (
            "forex_timestamp",
            Json.obj([
              ("type", Json.str("string")),
              ("description", Json.str("Optional timestamp for forex data.")),
            ]),
          ),
        ]),
      ),
      (
        "required",
        Json.arr([
          Json.str("rate"),
          Json.str("timestamp"),
          Json.str("base_asset"),
          Json.str("quote_asset"),
          Json.str("decimals"),
        ]),
      ),
    ]);
  };

  public func handle(context : ToolContext.ToolContext) : (_args : McpTypes.JsonValue, _auth : ?AuthTypes.AuthInfo, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) -> async () {

    func(_args : McpTypes.JsonValue, _auth : ?AuthTypes.AuthInfo, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) : async () {
      // Utility error/success
      func makeError(message : Text) {
        cb(#ok({ content = [#text({ text = message })]; isError = true; structuredContent = null }));
      };
      func ok(structured : Json.Json) {
        cb(#ok({ content = [#text({ text = Json.stringify(structured, null) })]; isError = false; structuredContent = ?structured }));
      };

      // Parse inputs
      let base_symbol = switch (Json.getAsText(_args, "base_asset_symbol")) {
        case (#ok t) t;
        case _ return makeError("Missing 'base_asset_symbol'");
      };

      let base_class_str = switch (Json.getAsText(_args, "base_asset_class")) {
        case (#ok t) t;
        case _ return makeError("Missing 'base_asset_class'");
      };

      let base_class : AssetClass = switch (base_class_str) {
        case ("Cryptocurrency") #Cryptocurrency;
        case ("FiatCurrency") #FiatCurrency;
        case _ return makeError("Invalid 'base_asset_class'. Must be 'Cryptocurrency' or 'FiatCurrency'");
      };

      let quote_symbol = switch (Json.getAsText(_args, "quote_asset_symbol")) {
        case (#ok t) t;
        case _ return makeError("Missing 'quote_asset_symbol'");
      };

      let quote_class_str = switch (Json.getAsText(_args, "quote_asset_class")) {
        case (#ok t) t;
        case _ return makeError("Missing 'quote_asset_class'");
      };

      let quote_class : AssetClass = switch (quote_class_str) {
        case ("Cryptocurrency") #Cryptocurrency;
        case ("FiatCurrency") #FiatCurrency;
        case _ return makeError("Invalid 'quote_asset_class'. Must be 'Cryptocurrency' or 'FiatCurrency'");
      };

      let timestamp_opt : ?Nat64 = switch (Json.getAsText(_args, "timestamp")) {
        case (#ok "") null;
        case (#ok s) {
          switch (Nat.fromText(s)) {
            case (?n) ?Nat64.fromNat(n);
            case null return makeError("Invalid 'timestamp' format");
          };
        };
        case _ null;
      };

      let exchangeRateCanister = actor (Principal.toText(context.exchangeRateCanisterId)) : Self;

      try {
        let request : GetExchangeRateRequest = {
          base_asset = { symbol = base_symbol; class_ = base_class };
          quote_asset = { symbol = quote_symbol; class_ = quote_class };
          timestamp = timestamp_opt;
        };

        let result = await exchangeRateCanister.get_exchange_rate(request);

        switch (result) {
          case (#Ok(rate)) {
            let base_asset_str = base_symbol # " (" # (if (base_class == #Cryptocurrency) "Cryptocurrency" else "FiatCurrency") # ")";
            let quote_asset_str = quote_symbol # " (" # (if (quote_class == #Cryptocurrency) "Cryptocurrency" else "FiatCurrency") # ")";

            let forex_ts_str = switch (rate.metadata.forex_timestamp) {
              case (?ts) Nat.toText(Nat64.toNat(ts));
              case null "N/A";
            };

            let out = Json.obj([
              ("rate", Json.str(Nat.toText(Nat64.toNat(rate.rate)))),
              ("timestamp", Json.str(Nat.toText(Nat64.toNat(rate.timestamp)))),
              ("base_asset", Json.str(base_asset_str)),
              ("quote_asset", Json.str(quote_asset_str)),
              ("decimals", #number(#int(Nat32.toNat(rate.metadata.decimals)))),
              ("base_asset_num_queried_sources", Json.str(Nat.toText(Nat64.toNat(rate.metadata.base_asset_num_queried_sources)))),
              ("base_asset_num_received_rates", Json.str(Nat.toText(Nat64.toNat(rate.metadata.base_asset_num_received_rates)))),
              ("quote_asset_num_queried_sources", Json.str(Nat.toText(Nat64.toNat(rate.metadata.quote_asset_num_queried_sources)))),
              ("quote_asset_num_received_rates", Json.str(Nat.toText(Nat64.toNat(rate.metadata.quote_asset_num_received_rates)))),
              ("standard_deviation", Json.str(Nat.toText(Nat64.toNat(rate.metadata.standard_deviation)))),
              ("forex_timestamp", Json.str(forex_ts_str)),
            ]);

            ok(out);
          };
          case (#Err(err)) {
            let errMsg = switch (err) {
              case (#AnonymousPrincipalNotAllowed) "Anonymous principal not allowed";
              case (#CryptoQuoteAssetNotFound) "Cryptocurrency quote asset not found";
              case (#FailedToAcceptCycles) "Failed to accept cycles";
              case (#ForexBaseAssetNotFound) "Forex base asset not found";
              case (#CryptoBaseAssetNotFound) "Cryptocurrency base asset not found";
              case (#StablecoinRateTooFewRates) "Stablecoin rate: too few rates";
              case (#ForexAssetsNotFound) "Forex assets not found";
              case (#InconsistentRatesReceived) "Inconsistent rates received";
              case (#RateLimited) "Rate limited";
              case (#StablecoinRateZeroRate) "Stablecoin rate: zero rate";
              case (#Other(o)) "Other error (code " # Nat32.toText(o.code) # "): " # o.description;
              case (#ForexInvalidTimestamp) "Forex: invalid timestamp";
              case (#NotEnoughCycles) "Not enough cycles";
              case (#ForexQuoteAssetNotFound) "Forex quote asset not found";
              case (#StablecoinRateNotFound) "Stablecoin rate not found";
              case (#Pending) "Request pending";
            };
            makeError("Exchange rate error: " # errMsg);
          };
        };
      } catch (e) {
        makeError("Failed to fetch exchange rate: " # Error.message(e));
      };
    };
  };
};
