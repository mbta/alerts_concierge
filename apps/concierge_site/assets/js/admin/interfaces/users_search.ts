import User from "./user";

export default interface UsersSearch {
  hasResults: boolean;
  isSearching: boolean;
  query?: string;
  results?: Array<User>;
}
