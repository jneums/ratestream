import Principal "mo:base/Principal";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";
import Result "mo:base/Result";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";

module ToolContext {
  /// Context shared between tools and the main canister
  public type ToolContext = {
    /// The principal of the canister
    canisterPrincipal : Principal;
    /// The owner of the canister
    owner : Principal;
    /// Exchange Rate Canister ID
    exchangeRateCanisterId : Principal;

    /// Add more shared state here as needed
  };

  /// Authorization result
  public type AuthResult = Result.Result<(), Text>;

  /// Reusable function to check if the caller is authorized (owner)
  /// Returns #ok(()) if authorized, #err(message) if not
  public func checkOwnerAuth(context : ToolContext, auth : ?AuthTypes.AuthInfo) : AuthResult {
    switch (auth) {
      case (null) {
        #err("Authentication required: No authentication information provided");
      };
      case (?authInfo) {
        // Check if the authenticated principal matches the owner
        if (Principal.equal(authInfo.principal, context.owner)) {
          #ok(());
        } else {
          #err("Unauthorized: Only the canister owner can perform this action");
        };
      };
    };
  };

  /// Helper function to create an unauthorized error response
  public func makeUnauthorizedError(message : Text, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) {
    cb(#ok({ content = [#text({ text = "Error: " # message })]; isError = true; structuredContent = null }));
  };
};
